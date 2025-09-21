#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试修复后的登录功能
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

from api.base import Chaoxing, Account

def test_login_fix():
    """测试修复后的登录功能"""
    print("🔧 测试登录修复效果")
    print("=" * 40)
    
    # 使用调试脚本中验证过的账号
    username = "19084630253" 
    password = "qq159741"
    
    print(f"测试账号: {username[:3]}****{username[-4:]}")
    
    # 创建账号对象
    account = Account(username, password)
    
    # 创建超星对象
    chaoxing = Chaoxing(account=account)
    
    # 测试登录
    print("🔄 正在测试登录...")
    login_result = chaoxing.login()
    
    print(f"登录结果: {login_result}")
    
    if login_result["status"]:
        print("✅ 登录成功!")
        
        # 测试获取课程列表
        print("🔄 正在获取课程列表...")
        try:
            courses = chaoxing.get_course_list()
            print(f"课程列表类型: {type(courses)}")
            print(f"课程数量: {len(courses) if courses else 0}")
            
            if courses:
                print("✅ 课程列表获取成功!")
                for i, course in enumerate(courses[:3], 1):  # 只显示前3门课程
                    print(f"   {i}. {course.get('title', '未知课程')} (ID: {course.get('courseId', 'N/A')})")
                if len(courses) > 3:
                    print(f"   ... 还有 {len(courses) - 3} 门课程")
            else:
                print("⚠️ 课程列表为空")
                
        except Exception as e:
            print(f"❌ 获取课程列表失败: {e}")
            import traceback
            traceback.print_exc()
            
    else:
        print(f"❌ 登录失败: {login_result['msg']}")

if __name__ == "__main__":
    try:
        test_login_fix()
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()

