from PIL import Image, ImageDraw, ImageFont
import qrcode,cv2
url='http://14.103.28.143:8081/'
img=Image.new('RGB',(1080,1440),'#faf7f2');d=ImageDraw.Draw(img)
regular='C:/Windows/Fonts/msyh.ttc';bold='C:/Windows/Fonts/msyhbd.ttc'
def font(n,b=False):return ImageFont.truetype(bold if b else regular,n)
def centered(text,y,size,color,b=False):
 f=font(size,b);box=d.textbbox((0,0),text,font=f);d.text(((1080-(box[2]-box[0]))/2,y),text,font=f,fill=color)
d.ellipse((795,-150,1280,335),fill='#f3e7d8');d.ellipse((-200,1150,230,1580),fill='#f3e7d8')
d.rounded_rectangle((75,76,171,172),radius=29,fill='#e76b32');d.text((94,88),'食',font=font(60,True),fill='white');d.text((196,79),'好好吃饭',font=font(42,True),fill='#302b27');d.text((198,139),'一餐一饭，认真做好',font=font(20),fill='#8a827b')
centered('今天，也要好好吃饭。',236,55,'#302b27',True)
centered('选一份喜欢的，把这一餐安排好',326,27,'#8a827b')
d.rounded_rectangle((132,413,948,1195),radius=44,fill='#eee5da');d.rounded_rectangle((120,401,960,1183),radius=44,fill='white')
centered('扫码订餐',451,42,'#302b27',True)
qr=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H,box_size=12,border=4);qr.add_data(url);qr.make(fit=True);code=qr.make_image(fill_color='#302b27',back_color='white').convert('RGB');size=code.width;img.paste(code,((1080-size)//2,535));d=ImageDraw.Draw(img)
d.rounded_rectangle((234,1059,846,1135),radius=38,fill='#e76b32');centered('微信扫一扫 · 打开菜单',1075,29,'white',True)
centered('选餐  ·  提交订单  ·  扫码付款',1241,26,'#8a827b')
centered('14.103.28.143:8081',1314,23,'#a29385')
img.save('订餐二维码.png',dpi=(300,300));code.save('订餐二维码-纯码.png')
value,_,_=cv2.QRCodeDetector().detectAndDecode(cv2.imread('订餐二维码.png'))
assert value==url,(value,url)
small=cv2.resize(cv2.imread('订餐二维码.png'),(540,720));value,_,_=cv2.QRCodeDetector().detectAndDecode(small);assert value==url
print('PASS: original and 540px poster decode to '+value)

