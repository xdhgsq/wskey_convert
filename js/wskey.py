# -*- coding: utf-8 -*-
'''
new Env('wskey转换');
'''
import base64
import hashlib
import hmac
import json
import logging
import os
import random
import time
import uuid

if "WSKEY_DEBUG" in os.environ:
    logging.basicConfig(level=logging.DEBUG, format='%(message)s')
    logger = logging.getLogger(__name__)
    logger.debug("\nDEBUG模式开启!\n")
else:
    logging.basicConfig(level=logging.INFO, format='%(message)s')
    logger = logging.getLogger(__name__)

try:
    import requests
except Exception as e:
    logger.info(str(e) + "\n缺少requests模块, 请执行命令：pip3 install requests\n")
    exit(1)
requests.packages.urllib3.disable_warnings()

ver = 40904

def ttotp(key):
    key = base64.b32decode(key.upper() + '=' * ((8 - len(key)) % 8))
    counter = struct.pack('>Q', int(time.time() / 30))
    mac = hmac.new(key, counter, 'sha1').digest()
    offset = mac[-1] & 0x0f
    binary = struct.unpack('>L', mac[offset:offset + 4])[0] & 0x7fffffff
    return str(binary)[-6:].zfill(6)

def sign_core(par):
    arr = [0x37, 0x92, 0x44, 0x68, 0xA5, 0x3D, 0xCC, 0x7F, 0xBB, 0xF, 0xD9, 0x88, 0xEE, 0x9A, 0xE9, 0x5A]
    key2 = b"80306f4370b39fd5630ad0529f77adb6"
    arr1 = [0 for _ in range(len(par))]
    for i in range(len(par)):
        r0 = int(par[i])
        r2 = arr[i & 0xf]
        r4 = int(key2[i & 7])
        r0 = r2 ^ r0
        r0 = r0 ^ r4
        r0 = r0 + r2
        r2 = r2 ^ r0
        r1 = int(key2[i & 7])
        r2 = r2 ^ r1
        arr1[i] = r2 & 0xff
    return bytes(arr1)

def get_sign(functionId, body, uuid, client, clientVersion, st, sv):
    all_arg = "functionId=%s&body=%s&uuid=%s&client=%s&clientVersion=%s&st=%s&sv=%s" % (
        functionId, body, uuid, client, clientVersion, st, sv)
    ret_bytes = sign_core(str.encode(all_arg))
    info = hashlib.md5(base64.b64encode(ret_bytes)).hexdigest()
    return info

def base64Encode(string):
    string1 = "KLMNOPQRSTABCDEFGHIJUVWXYZabcdopqrstuvwxefghijklmnyz0123456789+/"
    string2 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return base64.b64encode(string.encode("utf-8")).decode('utf-8').translate(str.maketrans(string1, string2))

def genJDUA():
    st = round(time.time() * 1000)
    aid = base64Encode(''.join(str(uuid.uuid4()).split('-'))[16:])
    oaid = base64Encode(''.join(str(uuid.uuid4()).split('-'))[16:])
    ua = 'jdapp;android;11.1.4;;;appBuild/98176;ef/1;ep/{"hdid":"JM9F1ywUPwflvMIpYPok0tt5k9kW4ArJEU3lfLhxBqw=","ts":%s,"ridx":-1,"cipher":{"sv":"CJS=","ad":"%s","od":"%s","ov":"CzO=","ud":"%s"},"ciphertype":5,"version":"1.2.0","appname":"com.jingdong.app.mall"};Mozilla/5.0 (Linux; Android 12; M2102K1C Build/SKQ1.220303.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/97.0.4692.98 Mobile Safari/537.36' % (st, aid, oaid, aid)
    return ua

def genParams():
    suid = ''.join(str(uuid.uuid4()).split('-'))[16:]
    buid = base64Encode(suid)
    st = round(time.time() * 1000)
    sv = random.choice(["102", "111", "120"])
    ep = json.dumps({
        "hdid": "JM9F1ywUPwflvMIpYPok0tt5k9kW4ArJEU3lfLhxBqw=",
        "ts": st,
        "ridx": -1,
        "cipher": {
            "area": "CV8yEJUzXzU0CNG0XzK=",
            "d_model": "JWunCVVidRTr",
            "wifiBssid": "dW5hbw93bq==",
            "osVersion": "CJS=",
            "d_brand": "WQvrb21f",
            "screen": "CJuyCMenCNq=",
            "uuid": buid,
            "aid": buid,
            "openudid": buid
        },
        "ciphertype": 5,
        "version": "1.2.0",
        "appname": "com.jingdong.app.mall"
    }).replace(" ", "")
    body = '{"to":"https%3a%2f%2fplogin.m.jd.com%2fjd-mlogin%2fstatic%2fhtml%2fappjmp_blank.html"}'
    sign = get_sign("genToken", body, suid, "android", "11.1.4", st, sv)
    params = {
        'functionId': 'genToken',
        'clientVersion': '11.1.4',
        'build': '98176',
        'client': 'android',
        'partner': 'google',
        'oaid': suid,
        'sdkVersion': '31',
        'lang': 'zh_CN',
        'harmonyOs': '0',
        'networkType': 'UNKNOWN',
        'uemps': '0-2',
        'ext': '{"prstate": "0", "pvcStu": "1"}',
        'eid': 'eidAcef08121fds9MoeSDdMRQ1aUTyb1TyPr2zKHk5Asiauw+K/WvS1Ben1cH6N0UnBd7lNM50XEa2kfCcA2wwThkxZc1MuCNtfU/oAMGBqadgres4BU',
        'ef': '1',
        'ep': ep,
        'st': st,
        'sign': sign,
        'sv': sv
    }
    return params

def getToken(wskey):
    params = genParams()
    headers = {
        'cookie': wskey,
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'charset': 'UTF-8',
        'accept-encoding': 'br,gzip,deflate',
        'user-agent': genJDUA()
    }
    url = 'https://api.m.jd.com/client.action'
    data = 'body=%7B%22to%22%3A%22https%253a%252f%252fplogin.m.jd.com%252fjd-mlogin%252fstatic%252fhtml%252fappjmp_blank.html%22%7D&'
    try:
        res = requests.post(url=url, params=params, headers=headers, data=data, verify=False, timeout=10)
        res_json = json.loads(res.text)
        tokenKey = res_json['tokenKey']
    except Exception as err:
        logger.info("JD_WSKEY接口抛出错误 尝试重试 更换IP")
        logger.info(str(err))
        return False
    else:
        return appjmp(wskey, tokenKey)

def appjmp(wskey, tokenKey):
    wskey = "pt_" + str(wskey.split(";")[0])
    if tokenKey == 'xxx':
        logger.info(str(wskey) + ";疑似IP风控等问题 默认为失效\n--------------------\n")
        return False
    headers = {
        'User-Agent': genJDUA(),
        'accept': 'accept:text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'x-requested-with': 'com.jingdong.app.mall'
    }
    params = {
        'tokenKey': tokenKey,
        'to': 'https://plogin.m.jd.com/jd-mlogin/static/html/appjmp_blank.html'
    }
    url = 'https://un.m.jd.com/cgi-bin/app/appjmp'
    try:
        res = requests.get(url=url, headers=headers, params=params, verify=False, allow_redirects=False, timeout=20)
    except Exception as err:
        logger.info("JD_appjmp 接口错误 请重试或者更换IP\n")
        logger.info(str(err))
        return False
    else:
        try:
            res_set = res.cookies.get_dict()
            pt_key = 'pt_key=' + res_set['pt_key']
            pt_pin = 'pt_pin=' + res_set['pt_pin']
            jd_ck = str(pt_key) + ';' + str(pt_pin) + ';'
        except Exception as err:
            logger.info("JD_appjmp提取Cookie错误 请重试或者更换IP\n")
            logger.info(str(err))
            return False
        else:
            if 'fake' in pt_key:
                logger.info(str(wskey) + ";WsKey状态失效\n")
                return False
            else:
                logger.info(str(wskey) + ";WsKey状态正常\n")
                return jd_ck

if __name__ == '__main__':
    if "WSCOOKIE" in os.environ:
        wskey = os.environ["WSCOOKIE"]
        result = getToken(wskey)
        if result:
            print("转换后的Cookie:", result)
        else:
            print("wskey转换失败")
    else:
        logger.info("未设置WSCOOKIE环境变量")
