#!/usr/bin/python
# -*- coding: UTF-8 -*-
# Jojess Nyxa 202407141243

import os, sys, network, socket, time, requests, array
from machine import Pin, SoftI2C
from lib_lcd1602_2004_with_i2c import LCD

# --------------------------------------------- #
wifissid = ''
wifipass = ''
host = "http://10.0.0.5:8096"
# --------------------------------------------- #
sda_pin = 4 # pin#6
scl_pin = 5 # pin#7
lcd = LCD(SoftI2C(scl=scl_pin, sda=sda_pin, freq=399361, timeout=50000))
# --------------------------------------------- #
loopCycle = 15
sleepyTimeLong = 4
sleepyTime = 2
sleepyTimeS15 = 1.5
sleepyTimeShort = 1
sleepyMicro = 0.5
sleepyPico = 0.2
# --------------------------------------------- #
pcq=0
progresschars = ( ".", "o", "O", "o" )
progresscharslen = len(progresschars) - 1
# --------------------------------------------- #
def msg(realm,msg):
    print("("+realm+") "+msg)
    return
# ------------------------------------------------------ #
def progresschar():
   global pcq
   pcq+=1
   if pcq > progresscharslen:
      pcq = 0
   return progresschars[pcq]
# ------------------------------------------------------ #
def pchx():
   global pcq
   lcd.puts(progresschar(),3,19)
   time.sleep(sleepyPico)
   return
# --------------------------------------------- #
def getR(keyname):
  getStr = ""
  gurl = host + '/'+keyname
  msg("get", gurl)
  pchx()
  try:
      time.sleep(sleepyMicro)
      getR = requests.get(gurl)
      getStr = str(getR.text)
  except:
      msg("error","getR fail:"+gurl)
  return getStr
# ------------------------------------------------------ #
def getDBW(realm, keyname):
   getStr = ""
   gurl = host+'/getDB?table=webdata&realm='+realm+'&name='+keyname
   msg("get", gurl)
   pchx()
   try:
      time.sleep(sleepyMicro)
      getX   = requests.get(gurl)
      getStr = str(getX.text)
   except:
       msg("error", "getDBW fail:" + gurl)
   return getStr
# ------------------------------------------------------ #
def getX(keyname):
   getStr = ""
   gurl = host+'/get?X='+keyname
   msg("get", gurl)
   pchx()
   try:
       time.sleep(sleepyMicro)
       getX   = requests.get(gurl)
       getStr = str(getX.text)
   except:
       msg("error", "getX fail:" + gurl)
   return getStr
# ------------------------------------------------------ #
def connect():
    wlan = network.WLAN(network.STA_IF)
    time.sleep(sleepyTimeShort)
    pchx()
    wlan.active(True)
    pchx()
    wlan.connect(wifissid, wifipass)
    for i in range(1, 10):
        pchx()
        time.sleep(sleepyTimeShort) # 1/2 sec
# ------------------------------------------------------ #    
def strSplit(s, chunksize=20):
    pos = 0
    while(pos != -1):
        new_pos = s.rfind(" ", pos, pos+chunksize)
        if(new_pos == pos):
            new_pos += chunksize # force split in word
        yield s[pos:new_pos]
        pos = new_pos
# ------------------------------------------------------ #    
time.sleep(sleepyTimeShort)
yeee="wifi up :3"
pchx()
lcd.clear()
pchx()
lcd.off()
pchx()
time.sleep(sleepyMicro)
pchx()
lcd.on()
pchx()
try:    
    connect()
except:
    yeee="wifi fail"

lcd.puts(yeee,1,0)
msg("wifi", yeee)



try:    
    jikanStr    = "some time? :3"
    tenkiStr    = "what weather?"
    jikanStrs   = "HH:MM:SS"
    updateStr   = "aaa"
    forecastShortLast = "mystery"
    forecastShort     = "mystery"
    forecastStr       = "mysterious weather"
    forecastLst       = ()
    aqiStr      = "uwu"
    tempNow     = "uwu"
    tempSoon    = "uwu"
    precips     = "uwu"
    precip      = "uwu"
    day         = "XXX"
    yymmdd      = "yymmdd"
    hhmmss      = "000000"
    visblty     = "999"
    try:
        time.sleep(sleepyMicro)
        getUpdt = requests.get(host + '/update')
        updateStr = str(getUpdt.text)
    except:
        msg("error", "get update failed")

    lq=loopCycle
    lqq=0
    while 1==1:
        lq += 1

        # - CYCLE_OUT ---------------------------------------------------------- #
        if lq >= loopCycle:
            lcd.puts("Frotting ... UwU",3,0)
            pchx()
            forecastShort = getDBW("weather", "Conditions") # get short form forecast - e.g.: "Partly Cloudy"
            forecastShort = forecastShort.lower() # lc
            forecastShort = forecastShort.replace(" ", "")        # strip spaces - e.g.: "partlycloudy"
            forecastShort = forecastShort[0:20]
            # --------------------------------- #
            forecastStr   = getDBW("weather","forecast")
            forecastLst   = strSplit( forecastStr )
            slq = 0
            for fs in forecastLst: 
                if slq == 0:
                    lcd.clear()
                lcd.puts(fs,slq,0)
                time.sleep(sleepyPico)
                slq+=1
                if slq > 3:
                    slq = 0
                    time.sleep(sleepyTimeS15)
            time.sleep(sleepyTimeShort)
            # --------------------------------- #
            
            jikanStr = getR("jikanStr20")
            updateStr = getR("update")
            tenkiStr = getR("tenki")
            aqiNull  = getR("aqi")
            visblty  = getDBW("weather", "visibility")
            moist    = getDBW("weather", "humidty")
            windStr  = getDBW("weather", "windnow")
            aqiStr   = getDBW("weather", "aqipm25")
            tempNow  = getDBW("weather", "tempnow")
            tempSoon = getDBW("weatherlog", "temp")
            precips  = getDBW("weatherlog", "precips")
            precip   = getDBW("weatherlog", "precip")            
            lcd.clear()
            lq = 0
        # - MAIN  ----------------------------------------- #
        time.sleep(sleepyMicro)

        jikanStr = getR("jikanStr20")
        msg("msg", jikanStr)
        lcd.puts(jikanStr,0,0)
        time.sleep(sleepyPico)
        
        Line1 = "T:"+tempNow +"~"+tempSoon
        Line1 = Line1+", P:"+ precip
        Line1 = Line1+", H:"+moist
        lcd.puts(Line1,1,0)
        time.sleep(sleepyPico)
        
        Line2 = "AQI:"+aqiStr
        Line2 = Line2+",W:"+windStr
        Line2 = Line2+",V:"+visblty
        lcd.puts(Line2,2,0)
        time.sleep(sleepyPico)
        
        Line3 = forecastShort
        lcd.puts(Line3,3,0)
        time.sleep(sleepyPico)
        
        time.sleep(sleepyTime)

except KeyboardInterrupt:
    msg("log", "quit!")