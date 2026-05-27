# 数据质量稽核工具 - Windows打包脚本
# 在Windows PowerShell中运行此脚本

Write-Host "=========================================="
Write-Host "数据质量稽核工具 - 打包脚本"
Write-Host "=========================================="
Write-Host ""

# 询问是否下载离线包
$downloadOffline = Read-Host "是否下载离线依赖包? (y/n，生产环境无网络请选y)"

if ($downloadOffline -eq "y") {
    Write-Host ""
    Write-Host "下载兼容Python 3.6的离线依赖包..."
    python download_packages.py --python-version 3.6
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "警告: 下载失败，尝试使用简化命令..."
        python download_packages.py
    }
}

Write-Host ""
Write-Host "开始打包项目..."
Write-Host ""

# 切换到上级目录
Set-Location ..

# 删除旧的压缩包
if (Test-Path "data-quality-audit-py.zip") {
    Remove-Item "data-quality-audit-py.zip" -Force
    Write-Host "已删除旧的压缩包"
}

# 打包项目
Write-Host "正在压缩..."
Compress-Archive -Path "data-quality-audit-py" -DestinationPath "data-quality-audit-py.zip" -Force -CompressionLevel Optimal

if ($?) {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "打包完成！"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "压缩包位置: data-quality-audit-py.zip"
    Write-Host "压缩包大小: $((Get-Item data-quality-audit-py.zip).Length / 1MB) MB"
    Write-Host ""
    Write-Host "下一步:"
    Write-Host "1. 上传 data-quality-audit-py.zip 到Linux服务器"
    Write-Host "2. 在服务器上解压: unzip data-quality-audit-py.zip"
    Write-Host "3. 测试兼容性: python3 test_compatibility.py"
    Write-Host "4. 运行部署: ./deploy.sh"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "错误: 打包失败"
    Write-Host ""
}

# 返回原目录
Set-Location data-quality-audit-py

Read-Host "按回车键退出"
