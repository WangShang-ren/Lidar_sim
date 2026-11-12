"""rqt plugin for FAST-LIO / Point-LIO tuning and starting the MID-360S driver."""

import contextlib
import io
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "/home/shaun/static/Mtools/lio_tune")

from python_qt_binding.QtCore import QProcess, Qt, QThread, Signal
from python_qt_binding.QtWidgets import (
    QCheckBox,
    QComboBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPlainTextEdit,
    QPushButton,
    QTableWidget,
    QTableWidgetItem,
    QVBoxLayout,
    QWidget,
)
from rqt_gui_py.plugin import Plugin

import lio_tune as lt


class Worker(QThread):
    log = Signal(str)
    done = Signal(bool, str)

    def __init__(self, fn, *args, **kwargs):
        super().__init__()
        self.fn = fn
        self.args = args
        self.kwargs = kwargs

    def run(self):
        buf = io.StringIO()
        try:
            with contextlib.redirect_stdout(buf):
                result = self.fn(*self.args, **self.kwargs)
        except Exception as exc:
            buf.write(f"\n[错误] {exc}\n")
            self.log.emit(buf.getvalue())
            self.done.emit(False, str(exc))
            return
        self.log.emit(buf.getvalue())
        self.done.emit(True, str(result))


class LioTunerWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.worker = None
        self.ros_process = None

        self.algo_combo = QComboBox()
        for name, item in lt.REGISTRY.items():
            self.algo_combo.addItem(item["label"], name)

        self.sim_check = QCheckBox("use_sim_time")

        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(["参数", "当前值"])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.setEditTriggers(QTableWidget.NoEditTriggers)
        self.table.setSelectionBehavior(QTableWidget.SelectRows)

        self.value_edit = QLineEdit()
        self.value_edit.setPlaceholderText("选中参数后输入新值")

        self.start_ros_btn = QPushButton("启动雷达+RViz")
        self.stop_ros_btn = QPushButton("停止雷达+RViz")
        self.restart_lio_btn = QPushButton("重启 LIO")
        self.stop_lio_btn = QPushButton("停止 LIO")
        self.apply_btn = QPushButton("应用")
        self.apply_restart_btn = QPushButton("应用+重启")
        self.rollback_btn = QPushButton("回滚")

        self.log_edit = QPlainTextEdit()
        self.log_edit.setReadOnly(True)
        self.log_edit.setMaximumBlockCount(3000)

        self._layout()
        self._connect()
        self.refresh_params()

    def _layout(self):
        top = QHBoxLayout()
        top.addWidget(QLabel("算法:"))
        top.addWidget(self.algo_combo)
        top.addStretch(1)
        top.addWidget(self.sim_check)

        ros_row = QHBoxLayout()
        ros_row.addWidget(self.start_ros_btn)
        ros_row.addWidget(self.stop_ros_btn)

        lio_row = QHBoxLayout()
        lio_row.addWidget(self.restart_lio_btn)
        lio_row.addWidget(self.stop_lio_btn)
        lio_row.addWidget(self.rollback_btn)

        edit_row = QHBoxLayout()
        edit_row.addWidget(self.value_edit)
        edit_row.addWidget(self.apply_btn)
        edit_row.addWidget(self.apply_restart_btn)

        root = QVBoxLayout(self)
        root.addLayout(top)
        root.addLayout(ros_row)
        root.addLayout(lio_row)
        root.addWidget(self.table, 1)
        root.addLayout(edit_row)
        root.addWidget(self.log_edit, 1)

    def _connect(self):
        self.algo_combo.currentIndexChanged.connect(self.refresh_params)
        self.table.itemSelectionChanged.connect(self._selection_changed)
        self.start_ros_btn.clicked.connect(self.start_ros)
        self.stop_ros_btn.clicked.connect(self.stop_ros)
        self.restart_lio_btn.clicked.connect(self.restart_lio)
        self.stop_lio_btn.clicked.connect(self.stop_lio)
        self.apply_btn.clicked.connect(lambda: self.apply_param(False))
        self.apply_restart_btn.clicked.connect(lambda: self.apply_param(True))
        self.rollback_btn.clicked.connect(self.rollback)

    def algo(self):
        return self.algo_combo.currentData()

    def log(self, text):
        self.log_edit.appendPlainText(text)

    def refresh_params(self):
        algo = self.algo()
        try:
            data = lt.load_yaml(lt.REGISTRY[algo]["active"])
            params = dict(lt.iter_params(lt.params_of(data)))
        except Exception as exc:
            self.log(f"[错误] 读取配置失败: {exc}")
            return
        self.table.setRowCount(0)
        for key, value in params.items():
            row = self.table.rowCount()
            self.table.insertRow(row)
            self.table.setItem(row, 0, QTableWidgetItem(key))
            self.table.setItem(row, 1, QTableWidgetItem(str(value)))

    def _selection_changed(self):
        row = self.table.currentRow()
        if row < 0:
            return
        value_item = self.table.item(row, 1)
        key_item = self.table.item(row, 0)
        if value_item and key_item:
            self.value_edit.setText(value_item.text())
            self.value_edit.setToolTip(key_item.text())

    def current_key(self):
        row = self.table.currentRow()
        if row < 0:
            return None
        item = self.table.item(row, 0)
        return item.text() if item else None

    def start_ros(self):
        if self.ros_process is not None and self.ros_process.state() == QProcess.Running:
            self.log("ROS 已经在运行")
            return
        cmd = (
            "set +u; "
            "unset AMENT_CURRENT_PREFIX COLCON_CURRENT_PREFIX; "
            "exec /home/shaun/static/tools/livox_ws/run_mid360s_rviz.sh"
        )
        self.ros_process = QProcess(self)
        self.ros_process.setProcessChannelMode(QProcess.MergedChannels)
        self.ros_process.readyReadStandardOutput.connect(self._ros_output)
        self.ros_process.start("bash", ["-lc", cmd])
        self.log("正在启动 MID360s 驱动 + RViz ...")

    def _ros_output(self):
        if self.ros_process:
            data = bytes(self.ros_process.readAllStandardOutput()).decode("utf-8", "replace")
            if data.strip():
                self.log(data.rstrip())

    def stop_ros(self):
        if self.ros_process is not None:
            self.ros_process.terminate()
            self.ros_process.waitForFinished(1500)
            self.ros_process.kill()
            self.ros_process = None
        subprocess.run(["pkill", "-x", "livox_ros_drive"], capture_output=True)
        subprocess.run(["pkill", "-x", "rviz2"], capture_output=True)
        self.log("已停止雷达驱动和 RViz")

    def restart_lio(self):
        algo = self.algo()
        sim = True if self.sim_check.isChecked() else None
        self._start_worker(self._task_restart, algo, sim)

    def stop_lio(self):
        algo = self.algo()
        lt.kill_processes(algo)
        self.log(f"已停止 {lt.REGISTRY[algo]['label']}")

    def apply_param(self, restart):
        key = self.current_key()
        value = self.value_edit.text().strip()
        if not key or not value:
            QMessageBox.warning(self, "提示", "请先选择参数并输入值")
            return
        algo = self.algo()
        sim = True if self.sim_check.isChecked() else None
        self._start_worker(self._task_set, algo, key, value, restart, sim)

    def rollback(self):
        self._start_worker(self._task_rollback)

    def _task_set(self, algo, key, value, restart, sim):
        old, new, backups = lt.write_param(algo, key, value)
        print(f"{key}: {old} -> {new}")
        if restart:
            ok = lt.restart(algo, sim=sim)
            print("重启成功" if ok else "重启失败")
        return ""

    def _task_restart(self, algo, sim):
        return lt.restart(algo, sim=sim)

    def _task_rollback(self):
        lt.rollback()
        return ""

    def _start_worker(self, fn, *args):
        if self.worker is not None and self.worker.isRunning():
            self.log("已有任务在运行")
            return
        self.worker = Worker(fn, *args)
        self.worker.log.connect(self.log)
        self.worker.done.connect(self._task_done)
        self.worker.start()

    def _task_done(self, ok, _message):
        self.worker = None
        self.refresh_params()


class LioTunerPlugin(Plugin):
    def __init__(self, context):
        super().__init__(context)
        self.setObjectName("LioTunerPlugin")
        self._widget = LioTunerWidget()
        context.add_widget(self._widget)
