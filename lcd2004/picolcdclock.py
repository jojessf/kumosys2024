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
# --------------------------------------------- #
def getR(keyname):
  getStr = ""
  gurl = host + '/'+keyname
  msg("get", gurl)
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
   try:
       time.sleep(sleepyMicro)
       getX   = requests.get(gurl)
       getStr = str(getX.text)
   except:
       msg("error", "getX fail:" + gurl)
   return getStr
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
time.sleep(sleepyTimeShort)
yeee="wifi up :3"
pchx()
try:    
    connect()
except:
    yeee="wifi fail"

lcd.puts(yeee,1,0)
msg("wifi", yeee)

pchx()
lcd.clear()
pchx()
lcd.off()
pchx()
time.sleep(sleepyMicro)
pchx()
lcd.on()
pchx()

lcd.puts(progresschar(),3,19)

try:    
    jikanStr    = "some time? :3"
    tenkiStr    = "what weather?"
    jikanStrs   = "HH:MM:SS"
    updateStr   = "aaa"
    forecastShortLast = "mystery"
    forecastShort     = "mystery"
    aqiStr      = "uwu"
    tempNow     = "uwu"
    tempSoon    = "uwu"
    precips     = "uwu"
    precip      = "uwu"
    day         = "XXX"
    yymmdd      = "yymmdd"
    hhmmss      = "000000"
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
            lcd.puts("UwU - refresh - UwU",3,0)
            pchx()
            forecastShort = getDBW("weather", "Conditions") # get short form forecast - e.g.: "Partly Cloudy"
            pchx()
            forecastShort = forecastShort.lower() # lc
            forecastShort = forecastShort.replace(" ", "")        # strip spaces - e.g.: "partlycloudy"
            forecastShort = forecastShort[0:20]
            jikanStr = getR("jikanStr20")
            pchx()
            updateStr = getR("update")
            pchx()
            tenkiStr = getR("tenki")
            pchx()
            aqiNull  = getR("aqi")
            pchx()
            aqiStr   = getDBW("weather", "aqipm25")
            pchx()
            tempNow  = getDBW("weather", "tempnow")
            pchx()
            tempSoon = getDBW("weatherlog", "temp")
            pchx()
            precips  = getDBW("weatherlog", "precips")
            pchx()
            precip   = getDBW("weatherlog", "precip")            
            pchx()
            lcd.clear()
            lq = 0
        # - MAIN  ----------------------------------------- #
        time.sleep(sleepyMicro)

        jikanStr = getR("jikanStr20")
        msg("msg", jikanStr)
        lcd.puts(jikanStr,0,0)
        time.sleep(sleepyPico)
        
        Line1 = "T: "+tempNow +"~"+tempSoon+" F,"
        Line1 = Line1 + " P: " + precip
        lcd.puts(Line1,1,0)
        time.sleep(sleepyPico)
        
        Line2 = "AQI: "+aqiStr+", "
        Line2 = Line2 
        lcd.puts(Line2,2,0)
        time.sleep(sleepyPico)
        
        Line3 = forecastShort
        lcd.puts(Line3,3,0)
        time.sleep(sleepyPico)
        
        time.sleep(sleepyTime)

except KeyboardInterrupt:
    msg("log", "quit!")