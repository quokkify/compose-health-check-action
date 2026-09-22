#!/usr/bin/env python3
"""Convert Bats JUnit XML into the bounded Allure result contract used by CI."""

from __future__ import annotations

import argparse
import hashlib
import json
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path


def status_for(testcase: ET.Element) -> tuple[str, dict[str, str]]:
    for tag, status in (("failure", "failed"), ("error", "broken"), ("skipped", "skipped")):
        node = testcase.find(tag)
        if node is not None:
            details = {
                key: value
                for key, value in {
                    "message": node.get("message", ""),
                    "trace": (node.text or "").strip(),
                }.items()
                if value
            }
            return status, details
    return "passed", {}


def convert(input_directory: Path, output_directory: Path, module: str) -> int:
    xml_files = sorted(input_directory.rglob("*.xml"))
    if not xml_files:
        raise SystemExit(f"No JUnit XML files found under {input_directory}")

    output_directory.mkdir(parents=True, exist_ok=True)
    converted = 0
    for xml_file in xml_files:
        root = ET.parse(xml_file).getroot()
        for index, testcase in enumerate(root.iter("testcase")):
            classname = testcase.get("classname", xml_file.stem)
            name = testcase.get("name", f"test-{index + 1}")
            full_name = f"{classname}::{name}"
            identifier = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{xml_file.name}:{full_name}:{index}"))
            status, details = status_for(testcase)
            duration_ms = max(1, round(float(testcase.get("time", "0")) * 1000))
            result = {
                "uuid": identifier,
                "historyId": hashlib.sha256(full_name.encode()).hexdigest(),
                "testCaseId": hashlib.sha256(full_name.encode()).hexdigest(),
                "name": name,
                "fullName": full_name,
                "status": status,
                "statusDetails": details,
                "stage": "finished",
                "start": 1,
                "stop": 1 + duration_ms,
                "labels": [
                    {"name": "framework", "value": "bats"},
                    {"name": "language", "value": "bash"},
                    {"name": "suite", "value": classname},
                    {"name": "epic", "value": "unit"},
                ],
            }
            (output_directory / f"{identifier}-result.json").write_text(
                json.dumps(result, ensure_ascii=False) + "\n", encoding="utf-8"
            )
            converted += 1

    if converted == 0:
        raise SystemExit("JUnit XML contained no test cases")
    (output_directory / "ci-env-fragment.properties").write_text(
        f"{module}.Module={module}\n{module}.Suite=Bats\n",
        encoding="utf-8",
    )
    return converted


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--module", required=True)
    args = parser.parse_args()
    allowed_module_characters = (
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._:-"
    )
    if not args.module or any(
        character not in allowed_module_characters for character in args.module
    ):
        parser.error("--module must contain only letters, digits, dots, underscores, colons, or hyphens")
    count = convert(args.input, args.output, args.module)
    print(f"Converted {count} Bats test case(s) into Allure results")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
