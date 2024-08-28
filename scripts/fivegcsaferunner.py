import argparse
import logging
import os
import re
import shutil
import subprocess
import sys
import time

logging.basicConfig(
    format="%(levelname)s: %(asctime)s %(message)s",
    datefmt="%m/%d/%Y %H:%M:%S ",
    level=logging.DEBUG,
)
DOWNLOAD_URL = "https://arm.sero.gic.ericsson.se/artifactory/proj-pc-fivegcsafe-release-local/com/ericsson/fivegc/"
SERO_API_KEY = "cmVmdGtuOjAxOjE3NDY2ODg2NTc6ejhnQ0hOaWZxTlZsMGNnbTRacnVuOGVTRXlF"
SUB_MODULE_NAME = "fivegcsafe-runner"
MIN_VERSION = "0.001"
VERSION_PATTERN = "^\d+\.\d{3}|latest$"
SUPPORT_RUN_SUITE_VERSION = "0.731"
JAVA8_VERSION = "1.8"
JAVA11_VERSION = "11"
SUPPORT_JAVA11_VERSION = "0.872"

def compare_versions(v1, v2):
    v1_parts = [int(part) for part in v1.split('.')]
    v2_parts = [int(part) for part in v2.split('.')]
    max_parts = max(len(v1_parts), len(v2_parts))

    # Add padding zeros to make the version parts equal in length
    v1_parts += [0] * (max_parts - len(v1_parts))
    v2_parts += [0] * (max_parts - len(v2_parts))

    # Compare each part of the version numbers
    for i in range(max_parts):
        if v1_parts[i] < v2_parts[i]:
            return -1
        elif v1_parts[i] > v2_parts[i]:
            return 1

    # The version numbers are equal
    return 0


def get_jar_package_version(package_version):
    pid = os.getpid()
    timestamp = int(time.perf_counter() * 1e9)
    metadata_file_path = f"/tmp/maven-metadata-{pid}-{timestamp}.xml"
    cmd = f"curl -H 'X-JFrog-Art-Api:{SERO_API_KEY}' -o{metadata_file_path} {DOWNLOAD_URL}{SUB_MODULE_NAME}/maven-metadata.xml"
    os.system(cmd)
    with open(metadata_file_path) as f:
        context = f.read()
        latest_version_reg = "<release>([\d\.]+)</release>"
        latest_version = re.search(latest_version_reg, context).group(1)
    os.remove(metadata_file_path)
    if package_version == "latest":
        return latest_version
    elif compare_versions(package_version, MIN_VERSION) == -1 or compare_versions(package_version, latest_version) == 1:
        logging.error(
            f"the version {package_version} is invalid, you have to provide a version in the range: {MIN_VERSION} - {latest_version}"
        )
        exit()
    else:
        return package_version


def download_artifacts(path_to_store_package, package_version):
    if not os.path.exists(path_to_store_package):
        os.makedirs(path_to_store_package)

    jar_file = os.path.join(path_to_store_package, f"{SUB_MODULE_NAME}-{package_version}.jar")
    package_md5_file = os.path.join(path_to_store_package, f"{SUB_MODULE_NAME}-{package_version}.jar.md5")
    if not os.path.exists(jar_file):
        logging.info("Prepare to download package")

        cmd = f"curl -H 'X-JFrog-Art-Api:{SERO_API_KEY}' -o{jar_file} \
            {DOWNLOAD_URL}{SUB_MODULE_NAME}/{package_version}/{SUB_MODULE_NAME}-{package_version}.jar"
        os.system(cmd)
        cmd = f"curl -H 'X-JFrog-Art-Api:{SERO_API_KEY}' -o{package_md5_file}  \
            {DOWNLOAD_URL}{SUB_MODULE_NAME}/{package_version}/{SUB_MODULE_NAME}-{package_version}.jar.md5 "
        os.system(cmd)
        jar_file_md5sum = f"md5sum {jar_file} | awk '{{print $1}}'"
        if os.popen(jar_file_md5sum).read().strip("\n") != open(
                package_md5_file).read():
            logging.error(
                f"{SUB_MODULE_NAME} package may not exist for broken, please download it manually."
            )
        os.remove(package_md5_file)
    else:
        logging.info(f"{SUB_MODULE_NAME} Jar package already exists!")


def get_runner_jar_path(path_to_store_package, package_version):
    runner_jar_file = os.path.join(path_to_store_package, f"{SUB_MODULE_NAME}-{package_version}.jar")
    if os.path.exists(runner_jar_file):
        return runner_jar_file
    else:
        logging.error(
            f"No {runner_jar_file} is found in {path_to_store_package}")


def validate_program_arguments(program_args):
    for arg in program_args:
        if not arg.startswith("-D"):
            raise ValueError(
                "Invaid program argument: {}, program argument should start with -D"
                .format(arg))


def extract_test_cases(runner_jar, program_args_str):
    suites_sub_path_in_jar = "fivegc_tests/testsuites/"
    cases_sub_path_in_jar = "fivegc_tests/testcases/"
    cases_path = "fivegcsafe-runner/src/main/resources/fivegc_tests/testcases/"
    if suites_sub_path_in_jar in program_args_str:
        if os.path.exists(cases_path):
            shutil.rmtree(cases_path)
        command = (f"mkdir -p {cases_path} && "
                   f"jar xvf {runner_jar} {cases_sub_path_in_jar} && "
                   f"mv {cases_sub_path_in_jar}/* {cases_path}")
        os.system(command)
        if os.path.exists(cases_path):
            return cases_path
        else:
            logging.error(f"{cases_path},Failed to extract {cases_sub_path_in_jar} from jar: {runner_jar}")
            sys.exit(1)
    return None


def check_java_version(java_path, fivegc_version):
    version_output = subprocess.check_output([f'{java_path}', '-version'], stderr=subprocess.STDOUT).decode("utf-8")
    version_pattern = '"(\d+\.?\d*).*"'
    version_number = re.search(version_pattern, version_output).groups()[0]
    if version_number.endswith(".0"):
        version_number = version_number[:-2]  # Remove '.0' from versions like '11.0'
    required_version = JAVA11_VERSION
    if compare_versions(fivegc_version, SUPPORT_JAVA11_VERSION) == -1:
        required_version = JAVA8_VERSION
    if version_number != required_version:
        logging.error(f"The current Java version is {version_number}, but the required version is {required_version}.")
        logging.error(f"Please config system default Java to version {required_version}, or input desired Java path with --java-path")
        sys.exit(1)

def run_fivegcsafe(program_args, path_to_store_package, package_version, java_path):
    validate_program_arguments(program_args)
    version = get_jar_package_version(package_version)
    check_java_version(java_path, version)
    download_artifacts(path_to_store_package, version)
    jar_package_path = get_runner_jar_path(path_to_store_package, version)
    program_args_str = " ".join(program_args)
    testcases_path = None
    if compare_versions(version, SUPPORT_RUN_SUITE_VERSION) == -1:
        testcases_path = extract_test_cases(jar_package_path, program_args_str)
    command = f"{java_path} {program_args_str} -jar {jar_package_path}"
    logging.info(f"Running the fivegcsafe by the command: {command}")
    try:
        result = os.system(command)
    except Exception as e:
        logging.error(f"Failed to run fivegcsafe by the command: {command}")
        sys.exit(1)
    finally:
        if testcases_path is not None and os.path.exists(testcases_path):
            shutil.rmtree(testcases_path)
    if result != 0:
      logging.error("The execution result of fivegcsafe running is failure. Please check the log for details.")
      sys.exit(result)


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=("""
==============This script is for running fivegcsafe cases.==============

Run case/suite:
    python3 fivegcsaferunner.py --jar <absolute directory path store jar> \\
            --version <fivegcsafe version> \\
            -Dfivegcsafe-config=<absolute fivegcsafe config file path"> \\
            -Dglobal.test.config-files-directory=<absolute directory path of config files directory> \\
            -Duser.name=<username> \\
            -Dglobal.test.suite-path=<relative test case/suite file path"> \\
            -Dglobal.test.test-report.skip-generation=<true or false> \\
            -Dglobal.test.fivegcsafe-log-level=<info or debug>
Run case/suite with external test case/suite and feature file:
    python3 fivegcsaferunner.py --jar <absolute directory path store jar> \\
            --version <fivegcsafe version> \\
            -Dfivegcsafe-config=<absolute fivegcsafe config file path> \\
            -Dglobal.test.config-files-directory=<absolute directory path of config files directory> \\
            -Duser.name=<username> \\
            -Dglobal.test.suite-path=<absolute test case/suite file path"> \\
            -Dcucumber.features=<absolute feature file path"> \\
            -Dglobal.test.test-report.skip-generation=<true or false> \\
            -Dglobal.test.fivegcsafe-log-level=<info or debug>

======================================================================
    """),
    )
    parser.add_argument("--jar",
                        "-j",
                        type=str,
                        default="./fivegcsafe_jars",
                        help="Path to store jar package.")
    parser.add_argument(
        "--version",
        "-v",
        type=str,
        default="latest",
        help=
        f"The fivegcsafe version. All available fivegcsafe versions could get from \
        {DOWNLOAD_URL}{SUB_MODULE_NAME},\
        for example 0.372. If not provided, the package version will be the latest.")
    parser.add_argument(
        "--java-path",
        "-J",
        type=str,
        default="java",
        help=
        f"The absolute path of Java {JAVA11_VERSION} or Java {JAVA8_VERSION} used to run fivegcsage, \
        for example: /app/vbuild/RHEL6-x86_64/jdk/11/bin/java, \
        Java {JAVA11_VERSION} is required for fivegcsafe 0.872 and above, \
        otherwise Java {JAVA8_VERSION} is required"
    )
    parser.add_argument("fivegcsafe_vm_options", nargs="*", action="store")
    args, program_args = parser.parse_known_args()
    if not re.match(VERSION_PATTERN, args.version):
        logging.error(
            "Wrong version format, please use --help to check the right format."
        )
        return
    run_fivegcsafe(program_args, args.jar, args.version, args.java_path)

if __name__ == "__main__":
    main()