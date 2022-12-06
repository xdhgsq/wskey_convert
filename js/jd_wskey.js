const request = require('request');
let wsCookie = '';
const setCookie = require('set-cookie-parser');
const UA =`JD4iPhone/167490920(iPhone;%20i0S;%20Scale/2.00)`;

if (process.env.WSCOOKIE && process.env.WSCOOKIE != "") {
  wsCookie = process.env.WSCOOKIE;
}

async function genToken(wsCookie) {
  const options = {
    method: 'POST',
    url: 'https://api.m.jd.com/client.action?functionId=genToken&clientVersion=10.3.5&client=android&uuid=bxHhdRDtdQe0d3GzoQThEK==&st=1644299516680&sv=102&sign=bba1dfacef955c8426cdc7ad7dd3ef27',
    headers: {
      Host: 'api.m.jd.com',
      Cookie: wsCookie,
      accept: '*/*',
      referer: '',
      'user-agent': UA,
      'accept-language': 'zh-Hans-CN;q=1, en-CN;q=0.9',
      'content-type': 'application/x-www-form-urlencoded;',
    },
    body: `body=%7B%22to%22%3A%22https%3A%2F%2Fhome.m.jd.com%2FmyJd%2Fnewhome.action%22%2C%22action%22%3A%22to%22%7D`,
  };
  return new Promise((resolve, reject) => {
    request(options, async function (error, response, body) {
      if (!error) {
        try {
          const data = JSON.parse(body);
          resolve(data);
        } catch (error) {
          resolve(body);
        }
      } else {
        console.log(error);
        reject(error);
      }
    });
  });
}
async function getJDCookie(tokenKey) {
  return new Promise((resolve, reject) => {
    request(
      {
        url: `https://un.m.jd.com/cgi-bin/app/appjmp?tokenKey=${tokenKey}&to=https%3A%2F%2Fhome.m.jd.com%2FmyJd%2Fnewhome.action`,
        method: 'GET',
        headers: {
          Connection: 'Keep-Alive',
          'Content-Type': 'application/x-www-form-urlencoded',
          Accept: 'application/json, text/plain, */*',
          'Accept-Language': 'zh-cn',
          'User-Agent': UA,
        },
        followRedirect: false,
      },
      async function (error, response, body) {
        if (!error) {
          try {
            const cookies = setCookie(response);
            const ck = {};
            cookies
              .filter((o) => o.name === 'pt_key' || o.name === 'pt_pin')
              .forEach((o) => {
                ck[o.name] = o.value;
              });

            resolve(`pt_key=${ck.pt_key};pt_pin=${ck.pt_pin};`);
          } catch (error) {
            console.log(error);
            resolve('');
          }
        } else {
          reject(error);
        }
      }
    );
  });
}

function randomWord(randomFlag, min, max){
  var str = "",
      range = min,
      arr = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
  // 随机产生
  if(randomFlag){
    range = Math.round(Math.random() * (max-min)) + min;
  }
  for(var i=0; i<range; i++){
    pos = Math.round(Math.random() * (arr.length-1));
    str += arr[pos];
  }
  return str;
}

/**
 * 生成随机 iPhoneID
 * @returns {string}
 */
 function randomString(e) {
  e = e || 32;
  let t = "abcdef0123456789", a = t.length, n = "";
  for (i = 0; i < e; i++)
    n += t.charAt(Math.floor(Math.random() * a));
  return n
}

const sleep = (ms) => {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
};

async function main() {
  console.log('转换前的wskey', wsCookie);
  const { tokenKey } = await genToken(wsCookie);
  const ck = await getJDCookie(tokenKey);
  console.log('转换后的Cookie', ck);
}
main();

