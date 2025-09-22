#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
课程选择调试脚本
用于诊断课程选择和实际学习不匹配的问题
"""

import sys
import json
from api.base import Chaoxing, Account
from api.answer import Tiku
from api.logger import logger

def debug_course_data():
    """调试课程数据结构"""
    print("=== 课程选择调试工具 ===")
    
    # 获取用户输入
    username = input("请输入用户名: ").strip()
    if not username:
        print("❌ 用户名不能为空")
        return
        
    password = input("请输入密码: ").strip()  
    if not password:
        print("❌ 密码不能为空")
        return

    try:
        # 初始化
        print("\n🔄 正在初始化...")
        tiku = Tiku()
        tiku.DISABLE = True  # 禁用题库加快调试
        
        chaoxing = Chaoxing(
            account=Account(username, password),
            tiku=tiku
        )
        
        # 登录
        print("🔄 正在登录...")
        state = chaoxing.login()
        if not state.get("status"):
            print(f"❌ 登录失败: {state.get('msg', '未知错误')}")
            return
            
        print("✅ 登录成功!")
        
        # 获取课程列表
        print("\n🔄 正在获取课程列表...")
        courses = chaoxing.get_course_list()
        
        if not courses:
            print("❌ 未获取到任何课程")
            return
            
        print(f"✅ 获取到 {len(courses)} 门课程")
        
        # 显示课程详细信息
        print("\n" + "="*80)
        print("课程详细信息:")
        print("="*80)
        
        for i, course in enumerate(courses):
            print(f"\n📖 课程 {i+1}:")
            print(f"   标题: {course.get('title', 'N/A')}")
            print(f"   课程ID: {course.get('courseId', 'N/A')}")
            print(f"   班级ID: {course.get('clazzId', 'N/A')}")
            print(f"   CPI: {course.get('cpi', 'N/A')}")
            print(f"   教师: {course.get('teacher', 'N/A')}")
            print(f"   角色ID: {course.get('roleid', 'N/A')}")
            print(f"   完整数据: {json.dumps(course, ensure_ascii=False, indent=2)}")
            
            # 验证关键字段
            missing_fields = []
            if not course.get('courseId'):
                missing_fields.append('courseId')
            if not course.get('clazzId'):
                missing_fields.append('clazzId')
            if not course.get('cpi'):
                missing_fields.append('cpi')
                
            if missing_fields:
                print(f"   ⚠️  缺失关键字段: {', '.join(missing_fields)}")
            else:
                print("   ✅ 关键字段完整")
        
        # 测试课程点获取
        print("\n" + "="*80)
        print("测试课程章节获取:")
        print("="*80)
        
        test_course = None
        for course in courses:
            if course.get('courseId') and course.get('clazzId') and course.get('cpi'):
                test_course = course
                break
                
        if test_course:
            print(f"\n🧪 测试课程: {test_course['title']}")
            try:
                print("🔄 正在获取课程章节...")
                points = chaoxing.get_course_point(
                    test_course['courseId'], 
                    test_course['clazzId'], 
                    test_course['cpi']
                )
                print(f"✅ 成功获取到 {len(points.get('points', []))} 个章节")
                
                # 显示前3个章节
                for i, point in enumerate(points.get('points', [])[:3]):
                    print(f"   📄 章节 {i+1}: {point.get('title', 'N/A')}")
                    
            except Exception as e:
                print(f"❌ 获取课程章节失败: {e}")
                print("🔍 这可能表明课程数据有问题!")
        else:
            print("❌ 没有找到具有完整关键字段的课程用于测试")
            
    except Exception as e:
        print(f"❌ 调试过程出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    debug_course_data()
