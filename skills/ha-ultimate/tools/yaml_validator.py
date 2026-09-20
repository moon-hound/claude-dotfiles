#!/usr/bin/env python3
"""YAML syntax validator for Home Assistant configuration files.
SOURCE: philippb/claude-homeassistant (carried verbatim)

Usage: python tools/yaml_validator.py [config_dir]
       Default config_dir: config/
"""

import sys
from pathlib import Path
from typing import List

import yaml


class HAYamlLoader(yaml.SafeLoader):
    """Custom YAML loader that handles Home Assistant specific tags."""
    pass


def include_constructor(loader, node):
    return f"!include {loader.construct_scalar(node)}"

def include_dir_named_constructor(loader, node):
    return f"!include_dir_named {loader.construct_scalar(node)}"

def include_dir_merge_named_constructor(loader, node):
    return f"!include_dir_merge_named {loader.construct_scalar(node)}"

def include_dir_merge_list_constructor(loader, node):
    return f"!include_dir_merge_list {loader.construct_scalar(node)}"

def include_dir_list_constructor(loader, node):
    return f"!include_dir_list {loader.construct_scalar(node)}"

def input_constructor(loader, node):
    return f"!input {loader.construct_scalar(node)}"

def secret_constructor(loader, node):
    return f"!secret {loader.construct_scalar(node)}"


HAYamlLoader.add_constructor("!include", include_constructor)
HAYamlLoader.add_constructor("!include_dir_merge_named", include_dir_merge_named_constructor)
HAYamlLoader.add_constructor("!include_dir_named", include_dir_named_constructor)
HAYamlLoader.add_constructor("!include_dir_merge_list", include_dir_merge_list_constructor)
HAYamlLoader.add_constructor("!include_dir_list", include_dir_list_constructor)
HAYamlLoader.add_constructor("!input", input_constructor)
HAYamlLoader.add_constructor("!secret", secret_constructor)


class YAMLValidator:
    def __init__(self, config_dir: str = "config"):
        self.config_dir = Path(config_dir)
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate_yaml_syntax(self, file_path: Path) -> bool:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                yaml.load(f, Loader=HAYamlLoader)
            return True
        except yaml.YAMLError as e:
            self.errors.append(f"{file_path}: YAML syntax error - {e}")
            return False
        except UnicodeDecodeError as e:
            self.errors.append(f"{file_path}: Encoding error - {e}")
            return False
        except Exception as e:
            self.errors.append(f"{file_path}: Unexpected error - {e}")
            return False

    def validate_file_encoding(self, file_path: Path) -> bool:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                f.read()
            return True
        except UnicodeDecodeError:
            self.errors.append(f"{file_path}: File must be UTF-8 encoded")
            return False

    def validate_configuration_structure(self, file_path: Path) -> bool:
        if file_path.name != "configuration.yaml":
            return True
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                config = yaml.load(f, Loader=HAYamlLoader)
            if not isinstance(config, dict):
                self.errors.append(f"{file_path}: Configuration must be a dictionary")
                return False
            if "homeassistant" not in config:
                self.warnings.append(f"{file_path}: Missing 'homeassistant' section")
            for key in ["discovery", "introduction"]:
                if key in config:
                    self.warnings.append(f"{file_path}: '{key}' is deprecated")
            return True
        except Exception as e:
            self.errors.append(f"{file_path}: Failed to validate structure - {e}")
            return False

    def validate_automations_structure(self, file_path: Path) -> bool:
        if file_path.name != "automations.yaml":
            return True
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                automations = yaml.load(f, Loader=HAYamlLoader)
            if automations is None:
                return True
            if not isinstance(automations, list):
                self.errors.append(f"{file_path}: Automations must be a list")
                return False
            all_valid = True
            for i, automation in enumerate(automations):
                if not isinstance(automation, dict):
                    self.errors.append(f"{file_path}: Automation {i} must be a dictionary")
                    all_valid = False
                    continue
                if "use_blueprint" not in automation:
                    if "trigger" not in automation and "triggers" not in automation:
                        self.errors.append(f"{file_path}: Automation {i} missing 'trigger' or 'triggers'")
                        all_valid = False
                    if "action" not in automation and "actions" not in automation:
                        self.errors.append(f"{file_path}: Automation {i} missing 'action' or 'actions'")
                        all_valid = False
                if "alias" not in automation:
                    self.warnings.append(f"{file_path}: Automation {i} missing 'alias' (recommended)")
            return all_valid
        except Exception as e:
            self.errors.append(f"{file_path}: Failed to validate automations structure - {e}")
            return False

    def validate_scripts_structure(self, file_path: Path) -> bool:
        if file_path.name != "scripts.yaml":
            return True
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                scripts = yaml.load(f, Loader=HAYamlLoader)
            if scripts is None:
                return True
            if not isinstance(scripts, dict):
                self.errors.append(f"{file_path}: Scripts must be a dictionary")
                return False
            all_valid = True
            for script_name, script_config in scripts.items():
                if not isinstance(script_config, dict):
                    self.errors.append(f"{file_path}: Script '{script_name}' must be a dictionary")
                    all_valid = False
                    continue
                if "use_blueprint" not in script_config and "sequence" not in script_config:
                    self.errors.append(f"{file_path}: Script '{script_name}' missing required 'sequence' or 'use_blueprint'")
                    all_valid = False
            return all_valid
        except Exception as e:
            self.errors.append(f"{file_path}: Failed to validate scripts structure - {e}")
            return False

    def get_yaml_files(self) -> List[Path]:
        yaml_files: List[Path] = []
        for pattern in ["*.yaml", "*.yml"]:
            yaml_files.extend(self.config_dir.glob(pattern))
        return yaml_files

    def validate_all(self) -> bool:
        if not self.config_dir.exists():
            self.errors.append(f"Config directory {self.config_dir} does not exist")
            return False
        yaml_files = self.get_yaml_files()
        if not yaml_files:
            self.warnings.append("No YAML files found in config directory")
            return True

        all_valid = True
        for file_path in yaml_files:
            if file_path.name == "secrets.yaml":
                continue
            if not self.validate_file_encoding(file_path):
                all_valid = False
                continue
            if not self.validate_yaml_syntax(file_path):
                all_valid = False
                continue
            self.validate_configuration_structure(file_path)
            self.validate_automations_structure(file_path)
            self.validate_scripts_structure(file_path)
        return all_valid

    def print_results(self):
        if self.errors:
            print("ERRORS:")
            for error in self.errors:
                print(f"  ❌ {error}")
            print()
        if self.warnings:
            print("WARNINGS:")
            for warning in self.warnings:
                print(f"  ⚠️  {warning}")
            print()
        if not self.errors and not self.warnings:
            print("✅ All YAML files are valid!")
        elif not self.errors:
            print("✅ YAML syntax is valid (with warnings)")
        else:
            print("❌ YAML validation failed")


def main():
    config_dir = sys.argv[1] if len(sys.argv) > 1 else "config"
    validator = YAMLValidator(config_dir)
    is_valid = validator.validate_all()
    validator.print_results()
    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
