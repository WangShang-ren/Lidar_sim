from setuptools import setup

package_name = "rqt_lio_tune"

setup(
    name=package_name,
    version="0.1.0",
    packages=[package_name],
    package_dir={"": "src"},
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name, ["package.xml", "plugin.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="shaun",
    maintainer_email="shaun@todo.todo",
    description="rqt plugin for FAST-LIO / Point-LIO parameter tuning and ROS startup.",
    license="Apache-2.0",
)
