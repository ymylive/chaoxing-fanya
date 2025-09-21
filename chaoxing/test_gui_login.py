#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试GUI登录功能是否正常工作
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

# 模拟GUI的LoginWorker
def test_gui_login_worker():
    """测试GUI中LoginWorker的逻辑"""
    print("🔧 测试GUI登录Worker逻辑")
    print("=" * 50)
    
    # 使用之前验证过的账号
    username = "19084630253"
    password = "qq159741"
    
    print(f"测试账号: {username[:3]}****{username[-4:]}")
    
    try:
        # 模拟LoginWorker的run方法
        from api.base import Chaoxing, Account
        from api.answer import Tiku
        
        print("✅ 成功导入 Chaoxing, Account, Tiku")
        
        # init tiku
        tiku = Tiku()
        tiku_conf = {
            "provider": "关闭题库",
            "submit": "",
            "cover_rate": "60",
            "delay": "0",
            "tokens": "",
            "true_list": "正确,对,√,是",
            "false_list": "错误,错,×,否,不对,不正确",
        }
        if tiku_conf:
            tiku.config_set(tiku_conf)
        tiku = tiku.get_tiku_from_config()
        tiku.init_tiku()
        
        print("✅ 成功初始化题库")
        
        chaoxing = Chaoxing(account=Account(username, password), tiku=tiku)
        print("✅ 成功创建Chaoxing对象")
        
        state = chaoxing.login()
        print(f"登录结果: {state}")
        
        if not state.get("status"):
            print(f"❌ 登录失败: {state.get('msg', '登录失败')}")
            return False
        
        print("✅ 登录成功!")
        
        courses = chaoxing.get_course_list()
        print(f"课程列表类型: {type(courses)}")
        print(f"课程数量: {len(courses) if courses else 0}")
        
        if courses:
            print("✅ 课程列表获取成功!")
            print("前3门课程:")
            for i, course in enumerate(courses[:3], 1):
                print(f"   {i}. {course.get('title', '未知课程')} (ID: {course.get('courseId', 'N/A')})")
            if len(courses) > 3:
                print(f"   ... 还有 {len(courses) - 3} 门课程")
            return True
        else:
            print("❌ 课程列表为空")
            return False
            
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("🧪 GUI登录功能完整测试")
    print("=" * 60)
    
    # 测试GUI登录逻辑
    login_success = test_gui_login_worker()
    
    print("\n" + "=" * 60)
    if login_success:
        print("🎉 GUI登录功能测试通过!")
        print("✅ 建议: 重启GUI应用程序，应该能看到课程列表")
    else:
        print("❌ GUI登录功能测试失败")
    
    print("\n🔧 重要提示:")
    print("   1. 完全关闭GUI应用程序")
    print("   2. 重新启动应用程序")
    print("   3. 使用相同的账号密码登录")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ 测试过程中出现错误: {e}")
        import traceback
        traceback.print_exc()

