#!/usr/bin/env python
# Copyright 2021 Bernard Jech
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import subprocess
try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

# this should be pulled in automatically
version = '0.98.1'

classifiers = [
    "Topic :: Utilities",
    "Programming Language :: Python",
]

setup(
    name = 'jazzhands_vault',
    version = version,
    url = 'http://www.jazzhands.net/',
    author = 'Bernard Jech',
    author_email = 'bernardjech@yahoo.com',
    license = 'ALv2',
    package_dir = {'': 'src/lib'},
    packages = ['jazzhands_vault'],
    description = 'Module for accessing Hashicorp Vault.',
    classifiers = classifiers,
)
