import os
import sys
from copy import copy, deepcopy

import argparse
import pprint
import textwrap
from pathlib import Path

pp = pprint.PrettyPrinter(indent=4)
PARAMETERS_EXCEPTION_LIST = ['5gc.test_report.skip_generation',
                             'global.test.config-files-directory',
                             'test.suite.path']


def main(input_args):
    args = _parse_args(input_args)
    repo_path = args.project_repo_path
    project = repo_path.split('/')[-1] if repo_path.split('/')[-1] else repo_path.split('/')[-2]

    supported_parameters = _get_all_supported_parameters(project, repo_path)
    sorted_supported_parameters = sorted(set(supported_parameters.keys()))

    if args.properties_file_to_migrate:
        input_parameters = _get_parameters_values_from_properties_file(args.properties_file_to_migrate)
        with open('generated_parameters.properties', 'w') as f:
            for p in sorted_supported_parameters:
                if p in input_parameters:
                    f.write(p + '=' + input_parameters[p] + "\n")
                else:
                    f.write(p + '=' + "\n")
        print(f' Generated generated_parameters.properties file in {os.getcwd()}\n')
        return
    if args.properties_file_to_compare:
        parameters = _get_parameters_from_properties_file(args.properties_file_to_compare)

        new_supported_parameters = sorted(
            list(set(supported_parameters.keys()) - set(parameters) - set(PARAMETERS_EXCEPTION_LIST)))
        unsupported_parameters = sorted(list(set(parameters) - set(supported_parameters.keys())))
        if new_supported_parameters:
            print('\n')
            print(f'There are {str(len(new_supported_parameters))} parameters supported by {project} '
                  f'but not present in {args.properties_file_to_compare}:')
            pp.pprint(new_supported_parameters)
            print('\n')
        if unsupported_parameters:
            print(f'There are {str(len(unsupported_parameters))} unsupported parameters by {project} '
                  f'but still present in {args.properties_file_to_compare}:')
            pp.pprint(unsupported_parameters)
            print('\n')
        return
    if args.generate:
        with open('generated_parameters.properties', 'w') as f:
            for p in sorted_supported_parameters:
                f.write(p + '=' + supported_parameters[p] + "\n")
        print(f' Generated generated_parameters.properties file in {os.getcwd()}\n')
        return
    print('\n')
    print(f'All supported parameters in {project}:\n')
    pp.pprint(sorted_supported_parameters)
    print(f'{str(len(supported_parameters))} supported parameters in total in {project}.')
    print('\n')
    return


def _parse_args(input_args):
    def _is_file(s):
        if not os.path.isfile(s):
            raise argparse.ArgumentTypeError("No such file: {}".format(s))
        return s

    desc = textwrap.dedent('''
The script is used to :
1. show all supported parameters in fivegcsafe;
Example: python3 fivegcsafe_parameters_helper.py -P /path/to/project/fivegcsafe
2. generate a plain properties file with all supported parameters in fivegcsafe
Example: python3 fivegcsafe_parameters_helper.py -P /path/to/project/fivegcsafe -G
3. generate and migrate values in provided properties file to a new properties file
Example: python3 fivegcsafe_parameters_helper.py -P /path/to/project/fivegcsafe -G -M /path/to/provided/parameters.properties
4. show the delta parameters between fivegcsafe supported parameters and the provided properties file.
Example: python3 fivegcsafe_parameters_helper.py -P /path/to/project/fivegcsafe -C /path/to/to_compare_parameters.properties
''')
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=desc)
    parser.add_argument(
        "-P",
        "--project_repo_path",
        type=str,
        required=True,
        help="Repo path of project fivegcsafe locally",
    )
    parser.add_argument(
        "-C",
        "--properties_file_to_compare",
        type=_is_file,
        help="Path of properties file to compare",
    )
    parser.add_argument(
        "-G",
        "--generate",
        action="store_true",
        default=False,
        help="Generate a plain properties file or not",
    )
    parser.add_argument(
        "-M",
        "--properties_file_to_migrate",
        type=_is_file,
        help="A properties file with parameters values could be to migrate the new generated properties file",
    )
    return parser.parse_args(input_args)


def _get_all_supported_parameters(project, repo_path):
    supported_parameters = {}
    java_properties_files = _get_java_properties_files_from_repo(repo_path)
    if project == 'fivegcsafe':
        for java_properties_file in java_properties_files:
            parameters = _get_parameters_from_java_properties_file(java_properties_file)
            supported_parameters.update(parameters)
        return supported_parameters
    else:
        raise RuntimeError("Not supported project {}", project)


def _get_java_properties_files_from_repo(repo_path):
    java_properties_files = Path(repo_path).rglob('*Properties.java')
    return java_properties_files


def _get_parameters_from_java_properties_file(java_properties_file_path):
    with open(java_properties_file_path, 'r') as f:
        lines = f.readlines()
    parameters = {}
    parameters_with_default_value = {}
    for line in lines:
        line = line.strip()
        if line.startswith('@Value'):
            # @Value("${global.test.config-files-directory}")
            # @Value("${5gc.pcc.admin.user:someAdmin}")
            parameter_string = line[len('@Value("${'): line.find('}")')].strip()
            if parameter_string.find(':') != -1:
                parameter_name = deepcopy(parameter_string)[:parameter_string.find(':')]
                parameter_value = deepcopy(parameter_string)[parameter_string.find(':')+1:]
                parameters_with_default_value[parameter_name] = parameter_value
            else:
                parameter_name = parameter_string
                parameter_value = ""
            parameters[parameter_name] = parameter_value

    # Temp functionality to print the parameters have default value in source code,
    # uncomment the below code to enable it
    # if parameters_with_default_value:
    #     print(f'Parameters with default value in {java_properties_file_path}: \n')
    #     pp.pprint(parameters_with_default_value)

    return parameters


def _get_parameters_from_properties_file(default_properties_file_path):
    with open(default_properties_file_path, 'r') as f:
        lines = f.readlines()
    parameters = []
    for line in lines:
        if line != '\n' and not line.startswith('#'):
            parameters.append(line.split('=')[0].strip())
    return parameters


def _get_parameters_values_from_properties_file(properties_file_path):
    with open(properties_file_path, 'r') as f:
        lines = f.readlines()
    parameters = {}
    for line in lines:
        if line != '\n' and not line.startswith('#'):
            parameters[line.split('=')[0].strip()] = line.split('=')[1].strip()
    return parameters


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as ex:
        raise SystemExit(ex)
