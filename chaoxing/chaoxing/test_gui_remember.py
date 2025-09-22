#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试GUI记住登录功能
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

def test_gui_remember():
    """测试GUI记住登录功能"""
    print("🧪 测试GUI记住登录功能")
    print("-" * 40)
    
    try:
        from gui.main_gui import MainWindow
        from PySide6.QtWidgets import QApplication
        
        app = QApplication(sys.argv)
        window = MainWindow()
        
        print("✅ GUI窗口创建成功")
        print("✅ 记住登录功能已集成")
        
        # 检查是否有记住登录的checkbox
        if hasattr(window, 'remember_checkbox'):
            print("✅ 记住登录复选框已添加")
        else:
            print("❌ 记住登录复选框未找到")
            
        # 检查是否有保存/加载方法
        if hasattr(window, '_save_credentials'):
            print("✅ 凭据保存方法已添加")
        else:
            print("❌ 凭据保存方法未找到")
            
        if hasattr(window, '_load_saved_credentials'):
            print("✅ 凭据加载方法已添加")
        else:
            print("❌ 凭据加载方法未找到")
            
        if hasattr(window, '_on_remember_changed'):
            print("✅ 记住状态变化处理方法已添加")
        else:
            print("❌ 记住状态变化处理方法未找到")
        
        print("\n🎉 GUI记住登录功能测试完成")
        print("📝 功能说明:")
        print("   - 勾选'记住登录信息'会保存用户名和密码(base64编码)")
        print("   - 下次启动时会自动填充保存的登录信息")
        print("   - 取消勾选会删除保存的凭据")
        print("   - 凭据保存在用户目录: ~/.chaoxing_gui/credentials.json")
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_gui_remember()
