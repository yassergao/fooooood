# 订餐网站与后台

服务器程序 server.cjs 使用 Node.js 内置模块，无 npm 依赖。后台地址 /admin。订单使用服务器文件原子写入，价格由服务器校验；相同提交凭证和请求编号不会重复创建订单。顾客通过浏览器随机凭证查看自己的订单，管理员使用密码和 HttpOnly 登录会话。后台支持按北京时间日期、状态、姓名/电话/地点筛选和菜品份数汇总，30 秒刷新。

上传 meal-order-backend.tar.gz 到服务器 /root，解压 deploy-backend.sh 后执行。脚本为现有 8081 订餐网站添加本机 3101 服务，生成管理员随机密码，保留旧静态目录，备份订餐配置和现有程序，打印回滚命令。80 与 8080 配置不修改。

订单数据：/var/lib/meal-order/orders.json，更新不会覆盖。密码：/etc/meal-order.env。服务：meal-order。查看日志：journalctl -u meal-order -n 80 --no-pager。修改密码后 systemctl restart meal-order（旧登录会话失效）。

部署后请完成一次手机试单，再登录后台确认，标记测试订单已取消。旧原型订单不会自动导入。没有在线支付功能。当前公网 HTTP 无传输加密，正式收集联系方式建议绑定域名并配置 HTTPS。浏览器清除数据或换设备后，顾客无法查看原浏览器订单，后台仍能查看。

本地验证：verify-backend.cjs 已验证顾客下单、未登录拦截、价格校验、无效份数、重复提交、后台状态更新、手机宽度和重启持久化。运行依赖 Playwright / Edge。
