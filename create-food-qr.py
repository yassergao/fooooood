from PIL import Image, ImageDraw, ImageFont, ImageOps
import qrcode,cv2
url='http://14.103.28.143:8081/'
img=Image.new('RGB',(1080,1680),'#faf7f2');d=ImageDraw.Draw(img)
regular='C:/Windows/Fonts/msyh.ttc';bold='C:/Windows/Fonts/msyhbd.ttc'
def font(n,b=False):return ImageFont.truetype(bold if b else regular,n)
def centered(text,y,size,color,b=False):
 f=font(size,b);box=d.textbbox((0,0),text,font=f);d.text(((1080-(box[2]-box[0]))/2,y),text,font=f,fill=color)
d.ellipse((830,-170,1280,310),fill='#f2e6d7')
d.rounded_rectangle((60,52,146,138),radius=26,fill='#e76b32');d.text((76,60),'食',font=font(55,True),fill='white');d.text((168,54),'好好吃饭',font=font(38,True),fill='#302b27');d.text((170,109),'一餐一饭，认真做好',font=font(19),fill='#8a827b')
centered('今天，也要好好吃饭。',195,55,'#302b27',True)
centered('选一份喜欢的，把这一餐安排好',279,26,'#8a827b')
for x,n,title,price in [(60,1,'卤肉饭','14.9'),(387,2,'照烧鸡腿饭','15.9'),(714,5,'番茄肉末意面','15.9')]:
 photo=ImageOps.fit(Image.open(f'{n}.jpg').convert('RGB'),(306,290),centering=(.5,.54))
 mask=Image.new('L',photo.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,305,289),radius=24,fill=255)
 img.paste(photo,(x,356),mask);d=ImageDraw.Draw(img);d.text((x+4,665),title,font=font(24,True),fill='#302b27');d.text((x+4,708),'¥'+price,font=font(25,True),fill='#e76b32')
d.rounded_rectangle((130,795,962,1510),radius=40,fill='#eee5da');d.rounded_rectangle((118,783,950,1498),radius=40,fill='white')
centered('扫码订餐',824,40,'#302b27',True)
qr=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H,box_size=12,border=4);qr.add_data(url);qr.make(fit=True);code=qr.make_image(fill_color='#302b27',back_color='white').convert('RGB');img.paste(code,((1080-code.width)//2,894));d=ImageDraw.Draw(img)
d.rounded_rectangle((225,1380,855,1454),radius=37,fill='#e76b32');centered('微信扫一扫 · 打开完整菜单',1397,27,'white',True)
centered('选餐  ·  提交订单  ·  扫码付款',1540,24,'#8a827b')
centered('14.103.28.143:8081',1600,21,'#a29385')
img.save('订餐二维码-美食版.png',dpi=(300,300))
for width in [1080,540]:
 picture=cv2.imread('订餐二维码-美食版.png');picture=cv2.resize(picture,(width,int(1680*width/1080)))
 value,_,_=cv2.QRCodeDetector().detectAndDecode(picture);assert value==url,(width,value)
print('PASS: food poster QR decodes at original and 540px')
