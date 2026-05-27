#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
下载离线依赖包
在有网络的环境运行此脚本，下载所有依赖到 offline_packages 目录

注意：
- 如果生产环境是 Python 3.6，需要下载兼容 Python 3.6 的包
- 使用 --python-version 参数指定目标Python版本
"""

import subprocess
import sys
import os
import argparse

def download_packages(python_version='3.6'):
    """下载依赖包到offline_packages目录"""
    
    # 创建目录
    os.makedirs('offline_packages', exist_ok=True)
    
    print("=" * 60)
    print("开始下载离线依赖包...")
    print("目标Python版本: {}".format(python_version))
    print("=" * 60)
    
    # 下载依赖 - 指定Python版本以确保兼容性
    cmd = [
        sys.executable, '-m', 'pip', 'download',
        '-r', 'requirements.txt',
        '-d', 'offline_packages',
        '--python-version', python_version,
        '--only-binary=:all:',  # 只下载wheel包
        '--platform', 'manylinux1_x86_64',  # Linux平台
        '--platform', 'manylinux2014_x86_64',
        '--abi', 'cp36',  # Python 3.6 ABI
        '--abi', 'none',  # 纯Python包
    ]
    
    print("\n执行命令:")
    print(" ".join(cmd))
    print("")
    
    try:
        subprocess.run(cmd, check=True)
        print("\n" + "=" * 60)
        print("依赖包下载完成！")
        print("=" * 60)
        print("\n离线包位置: offline_packages/")
        print("可以将整个项目目录打包传输到生产环境")
        print("\n注意: 如果下载失败，可以尝试不指定平台:")
        print("  pip download -r requirements.txt -d offline_packages")
    except subprocess.CalledProcessError as e:
        print("\n错误: 下载失败 - {}".format(e))
        print("\n尝试使用简化命令...")
        
        # 尝试简化命令
        simple_cmd = [
            sys.executable, '-m', 'pip', 'download',
            '-r', 'requirements.txt',
            '-d', 'offline_packages'
        ]
        try:
            subprocess.run(simple_cmd, check=True)
            print("\n使用简化命令下载成功！")
            print("注意: 这些包可能需要在目标环境编译")
        except:
            return 1
    
    return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='下载离线依赖包')
    parser.add_argument('--python-version', default='3.6', 
                       help='目标Python版本 (默认: 3.6)')
    args = parser.parse_args()
    
    sys.exit(download_packages(args.python_version))
