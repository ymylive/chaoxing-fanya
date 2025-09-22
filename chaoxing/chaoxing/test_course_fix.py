#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
快速测试课程选择修复
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from debug_course_selection import debug_course_data

if __name__ == "__main__":
    print("🔧 课程选择问题修复测试")
    print("这个脚本将帮助诊断课程选择和学习不匹配的问题")
    print("-" * 50)
    debug_course_data()
