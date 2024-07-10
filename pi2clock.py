#!/usr/bin/python
# -*- coding: UTF-8 -*-
# Jojess Nyxa 202407062353

import os
import sys 
import time
import logging
import requests
import textwrap
import spidev as SPI
sys.path.append("/home/jojess/st7789b")
from lib import LCD_1inch9
from PIL import Image, ImageDraw, ImageFont

# jojess spider daemon api access point
host = "http://10.0.0.5:8096/"

# Raspberry Pi pin configuration:
loopCycle = 4
sleepyTime = 2
sleepyTimeShort = 0.5
sleepyMicro = 0.25

RST = 27
DC = 25
BL = 18
bus = 0 
device = 0 
# logging.basicConfig(level = logging.DEBUG)
 
# --------------------------------------------- #
try:
    #disp = LCD_1inch9.LCD_1inch9(spi=SPI.SpiDev(bus, device),spi_freq=10000000,rst=RST,dc=DC,bl=BL)
    disp = LCD_1inch9.LCD_1inch9() # 320x170
    disp.Init()
    disp.clear()
    # disp.bl_DutyCycle(50) # backlight ~ 100%
    disp.bl_DutyCycle(15) # backlight ~ 100%
    Font1 = ImageFont.truetype("Font/Font01.ttf", 25)
    Font2 = ImageFont.truetype("Font/Font01.ttf", 35)
    Font3 = ImageFont.truetype("Font/Font02.ttf", 25)
    Font4 = ImageFont.truetype("Font/Font02.ttf", 32)
    Font5 = ImageFont.truetype("Font/Font02.ttf", 80)

    SplashyImages = ["img/rimurubanner_320_170.jpg"]
    SplashyImageL = len(SplashyImages)
    SplashyImageQ = 0
    

except IOError as e:
    logging.info(e)    
except KeyboardInterrupt:
    disp.module_exit()
    logging.info("quit:")
    exit()
# ------------------------------------------------------ #

def getR(keyname):
  getStr = ""
  try:
      time.sleep(sleepyMicro)
      getR = requests.get(host + '/'+keyname)
      getStr = str(getR.text)
  except IOError as e:
      logging.info(e)
  except:
      logging.info("getR fail")
  return getStr

def getX(keyname):
   getStr = ""
   try:
       time.sleep(sleepyMicro)
       getX   = requests.get(host+'/get?X='+keyname)
       getStr = str(getX.text)
   except IOError as e:
       logging.info(e)
   except:
       logging.info("getX fail")
   return getStr

def stringWrapToList(wid,str):
   str2=textwrap.fill(str,wid)
   list = str2.split("\n")
   return list
# ------------------------------------------------------ #
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# ------------------------------------------------------ #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/ #
# ------------------------------------------------------ #    
try:    
    jikanStr = "some time? :3"
    tenkiStr = "what weather?"
    jikanStrs = "HH:MM:SS"
    updateStr = "aaa"
    aqiStr    = "ZZZ"
    forecastShortLast = "mystery"
    try:
        time.sleep(sleepyMicro)
        getUpdt = requests.get(host + '/update')
        updateStr = str(getUpdt.text)
    except IOError as e:
        logging.info(e)
    except:
        logging.info("miscowo")


    lq=0
    lqq=0
    while 1==1:
        lq += 1
        
        if lq == 1:
           jikanStr   = getR("jikan")
           tenkiStr   = getR("tenki")
           aqiNull    = getR("aqi")
           aqiStr     = getX("aqipm25")
           tempNow    = getX("tempnow")
           tempSoon   = getX("temp")
           precips    = getX("precips")
           precip     = getX("precip")
           wind       = getX("windnow")
           pressure   = getX("pressure")
           dewpoint   = getX("dewpoint")
           visibility = getX("visibility") 
        
        
        # - CYCLE_OUT ---------------------------------------------------------- #
        if lq >= loopCycle:
            
            # get forecastShort / just load the icon
            forecastShort = getX("forecastShort") # get short form forecast - e.g.: "Partly Cloudy"
            forecastShort = forecastShort.lower() # lc
            forecastShort = forecastShort.replace(" ", "")        # strip spaces - e.g.: "partlycloudy"
            # print("forecastShort:" + forecastShort)
            # if forecastShort != forecastShortLast:
            #    try:
            #        print("wIco load:"+"img/weather/"+forecastShort+".jpg")
            #        wIco = Image.open("img/weather/"+forecastShort+".jpg")
            #    except IOError as e:
            #        print("e")
            #    except:
            #        print("miscuwu")
            #    forecastShortLast = forecastShort;
            # time.sleep(sleepyMicro)
            
            # - CYCLE_OUT / FORECAST ---------------------------------------------- #
            image2 = Image.new("RGB", (disp.height,disp.width ), "BLACK")
            draw = ImageDraw.Draw(image2)
            
            # try:
            #    disp.ShowImage(wIco)
            # except:
            #    print("invalid wIco type:"+forecastShort)
            # time.sleep(sleepyTime)
            
            y=0            # starting y 
            yInterval=30   # row height in pixels
            xWid=39        # row width in characters
            draw = ImageDraw.Draw(image2)
            forecastStr = getX("forecast")
            forecastLins = stringWrapToList(xWid,forecastStr)
            forecastLins.append("")
            forecastLins.append(forecastShort)
            for lin in forecastLins:
               if y <= disp.height - yInterval:
                  draw.text((0, y), lin, fill = "MAGENTA", font=Font3)
               y=y+yInterval
            
            disp.ShowImage(image2)
            for i in range(0,3,1):
               time.sleep(sleepyTime)
            
            # - CYCLE_OUT / CONDITIONS --------------------------------------------- #
            image2 = Image.new("RGB", (disp.height,disp.width ), "BLACK")
            draw = ImageDraw.Draw(image2)

  
            aqiStr     = getX("aqipm25")
            tempNow    = getX("tempnow")
            tempSoon   = getX("temp")
            precips    = getX("precips")
            precip     = getX("precip")
            wind       = getX("windnow")
            pressure   = getX("pressure") 
            dewpoint   = getX("dewpoint")
            visibility = getX("visibility")
            
            # image4 = Image.new("RGB", (disp.height,disp.width ), "WHITE")
            # draw = ImageDraw.Draw(image2)
            
            getJikans = requests.get(host + '/jikans')
            jikanStrs = str(getJikans.text)
            
            draw.text((0, 2), u"今>"+jikanStrs, fill = "MAGENTA", font=Font3)
            
            draw.text((0, 30),u"雨> ", fill = "BLUE", font=Font3)
            draw.text((50,27), precip, fill = "BLUE", font=Font3)
            draw.text((0, 55),u"露> ", fill = "BLUE", font=Font3)
            draw.text((50,52), dewpoint, fill = "BLUE", font=Font3)
           
            # draw.text((100, 30),u"> ", fill = "BLUE", font=Font3)
            # draw.text((150,27), , fill = "BLUE", font=Font3)
            draw.text((100, 55),u"目> ", fill = "CYAN", font=Font3)
            draw.text((150,52), visibility, fill = "CYAN", font=Font3)
           
            
            draw.text((  0, 88), u"壓", fill = "CYAN", font=Font3)
            draw.text(( 20, 88), pressure, fill = "CYAN", font=Font4)
            
            draw.text((100, 88), u"風", fill = "LIGHTBLUE", font=Font3)
            draw.text((150, 88), wind, fill = "LIGHTBLUE", font=Font4)

            disp.ShowImage(image2)
            for i in range(0,3,1):
               time.sleep(sleepyTime)
            
            # - CYCLE_OUT / BIG CLOCK ---------------------------------------------- #
            image2 = Image.new("RGB", (disp.height,disp.width ), "BLACK")
            draw = ImageDraw.Draw(image2)
            for i in range(0,3,1):
                try:
                    time.sleep(sleepyMicro)
                    getJikans = requests.get(host + '/jikans')
                    jikanStrs = str(getJikans.text)
                except IOError as e:
                    logging.info(e)
                except:
                    logging.info("miscowo")

                if i == 0:
                    try:
                        time.sleep(sleepyMicro)
                        getUpdt = requests.get(host + '/update')
                        updateStr = str(getUpdt.text)
                    except IOError as e:
                        logging.info(e)
                    except:
                        logging.info("miscowo")

                image3 = Image.new("RGB", (disp.height,disp.width ), "BLACK")
                draw3 = ImageDraw.Draw(image3)
                draw3.text((15, 35), jikanStrs, fill = "MAGENTA", font=Font5)
                disp.ShowImage(image3)
                time.sleep(sleepyTimeShort)
                lq=0
                
                
            # - CYCLE_OUT / IMG SPLASH -------------------------------------------- #
            if SplashyImageQ >= SplashyImageL:
               SplashyImageQ = 0
            logging.info("show image:" + SplashyImages[SplashyImageQ])
            splash = Image.open(SplashyImages[SplashyImageQ])
            disp.ShowImage(splash)
            time.sleep(sleepyTimeShort)
            SplashyImageQ += 1
           

        # - WEATHER DENSE ----------------------------------------- #
        image2 = Image.new("RGB", (disp.height,disp.width ), "BLACK")
        draw = ImageDraw.Draw(image2)
        
        jikanStr   = getR("jikan")
        # tenkiStr   = getR("tenki")
        # aqiNull    = getR("aqi")
        # aqiStr     = getX("aqipm25")
        # tempNow    = getX("tempnow")
        # tempSoon   = getX("temp")
        # precips    = getX("precips")
        # precip     = getX("precip")
        # wind       = getX("windnow")
        # pressure   = getX("pressure")
        # dewpoint   = getX("dewpoint")
        # visibility = getX("visibility")

        # image4 = Image.new("RGB", (disp.height,disp.width ), "WHITE")
        # draw = ImageDraw.Draw(image2)

        draw.text((0, 2), u"時間>"+jikanStr, fill = "MAGENTA", font=Font3)
        
        draw.text((0, 30),u"天氣> ", fill = "ORANGE", font=Font3)
        draw.text((50,27), tenkiStr, fill = "ORANGE", font=Font3)
        draw.text((0, 55),u"雨雷> ", fill = "BLUE", font=Font3)
        draw.text((50,52), precips, fill = "BLUE", font=Font3)
        
        
        draw.text((  0, 78), u"温", fill = "ORANGE", font=Font3)
        draw.text((  0, 90), tempNow, fill = "ORANGE", font=Font5)
        
        draw.text((125, 78), u"空", fill = "PURPLE", font=Font3)
        draw.text((125, 90), aqiStr, fill = "MAGENTA", font=Font5)
        
        draw.text((240, 78), u"雨", fill = "BLUE", font=Font3)
        draw.text((240, 90), precip, fill = "BLUE", font=Font5)

        disp.ShowImage(image2)
        time.sleep(sleepyTime)

    disp.module_exit()
    
except IOError as e:
    logging.info(e)    
    
except KeyboardInterrupt:
    disp.module_exit()
    logging.info("quit:")
    exit()
    
print("wat")
exit()

# ------------------------------------------------------ #
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# ------------------------------------------------------ #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/ #
# ------------------------------------------------------ #

# ------------------------------------------------------ #
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# ------------------------------------------------------ #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/ #
# ------------------------------------------------------ #

# ------------------------------------------------------ #
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# ------------------------------------------------------ #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/ #
# ------------------------------------------------------ #

# ------------------------------------------------------ #
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ #
# ------------------------------------------------------ #
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/ #
# ------------------------------------------------------ #

try:
    # display with hardware SPI:
    ''' Warning!!!Don't  creation of multiple displayer objects!!! '''
    #disp = LCD_1inch9.LCD_1inch9(spi=SPI.SpiDev(bus, device),spi_freq=10000000,rst=RST,dc=DC,bl=BL)
    disp = LCD_1inch9.LCD_1inch9()
    # Initialize library.
    disp.Init()
    # Clear display.
    disp.clear()
    #Set the backlight to 100
    disp.bl_DutyCycle(50)
    
    
    Font1 = ImageFont.truetype("../Font/Font01.ttf", 25)
    Font2 = ImageFont.truetype("../Font/Font01.ttf", 35)
    Font3 = ImageFont.truetype("../Font/Font02.ttf", 32)

    # Create blank image for drawing.
    image1 = Image.new("RGB", (disp.width,disp.height ), "WHITE")
    draw = ImageDraw.Draw(image1)

    logging.info("draw point")
    draw.rectangle((5, 10, 6, 11), fill = "BLACK")
    draw.rectangle((5, 25, 7, 27), fill = "BLACK")
    draw.rectangle((5, 40, 8, 43), fill = "BLACK")
    draw.rectangle((5, 55, 9, 59), fill = "BLACK")

    logging.info("draw rectangle")
    draw.rectangle([(20, 10), (70, 60)], fill = "WHITE", outline="BLUE")
    draw.rectangle([(85, 10), (130, 60)], fill = "BLUE")

    logging.info("draw line")
    draw.line([(20, 10), (70, 60)], fill = "RED", width = 1)
    draw.line([(70, 10), (20, 60)], fill = "RED", width = 1)
    draw.line([(110, 65), (110, 115)], fill = "RED", width = 1)
    draw.line([(85, 90), (135, 90)], fill = "RED", width = 1)

    logging.info("draw circle")
    draw.arc((85, 65, 135, 115), 0, 360, fill =(0, 255, 0))
    draw.ellipse((20, 65, 70, 115), fill = (0, 255, 0))

    logging.info("draw text")
    draw.rectangle([(0, 120), (140, 153)], fill = "BLUE")
    draw.text((5, 120), 'OwO', fill = "RED", font=Font1)
    draw.rectangle([(0,155), (172, 195)], fill = "RED")
    draw.text((1, 155), 'UwU', fill = "WHITE", font=Font2)
    draw.text((5, 190), 'nyanyanya', fill = "GREEN", font=Font3)
    
    disp.ShowImage(image1)
    time.sleep(2)
    disp.clear()
    exit()
    
    text= u"微雪电子"
    draw.text((5, 230),text, fill = "BLUE", font=Font3)
    image1=image1.rotate(0)
    disp.ShowImage(image1)
    time.sleep(2)
    
    image2 = Image.new("RGB", (disp.height,disp.width ), "WHITE")
    draw = ImageDraw.Draw(image2)
    draw.text((70, 2), u"西风吹老洞庭波，", fill = "BLUE", font=Font3)
    draw.text((70, 42), u"一夜湘君白发多。", fill = "RED", font=Font3)
    draw.text((70, 82), u"醉后不知天在水，", fill = "GREEN", font=Font3)
    draw.text((70, 122), u"满船清梦压星河。", fill = "BLACK", font=Font3)
    image2=image2.rotate(0)
    disp.ShowImage(image2)
    time.sleep(2)
    
    logging.info("show image")
    ImagePath = ["../pic/LCD_1inch9_1.jpg", "../pic/LCD_1inch9_2.jpg", "../pic/LCD_1inch9_3.jpg"]
    for i in range(0, 3):
        image = Image.open(ImagePath[i])	
        # image = image.rotate(0)
        disp.ShowImage(image)
        time.sleep(2)
    disp.module_exit()
    logging.info("quit:")
    
except IOError as e:
    logging.info(e)    
    
except KeyboardInterrupt:
    disp.module_exit()
    logging.info("quit:")
    exit()
