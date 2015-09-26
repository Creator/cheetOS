-- Minified SHA256 lib by GravityScore found here: http://www.computercraft.info/forums2/index.php?/topic/8169-sha-256-in-pure-lua/
local a=2^32;local b=a-1;local function c(d)local mt={}local e=setmetatable({},mt)function mt:__index(f)local g=d(f)e[f]=g;return g end;return e end;local function h(e,i)local function j(k,l)local m,o=0,1;while k~=0 and l~=0 do local p,q=k%i,l%i;m=m+e[p][q]*o;k=(k-p)/i;l=(l-q)/i;o=o*i end;m=m+(k+l)*o;return m end;return j end;local function r(e)local s=h(e,2^1)local t=c(function(k)return c(function(l)return s(k,l)end)end)return h(t,2^e.n or 1)end;local u=r({[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0},n=4})local function v(k,l,w,...)local x=nil;if l then k=k%a;l=l%a;x=u(k,l)if w then x=v(x,w,...)end;return x elseif k then return k%a else return 0 end end;local function y(k,l,w,...)local x;if l then k=k%a;l=l%a;x=(k+l-u(k,l))/2;if w then x=bit32_band(x,w,...)end;return x elseif k then return k%a else return b end end;local function z(A)return(-1-A)%a end;local function B(k,C)if C<0 then return lshift(k,-C)end;return math.floor(k%2^32/2^C)end;local function D(A,C)if C>31 or C<-31 then return 0 end;return B(A%a,C)end;local function lshift(k,C)if C<0 then return D(k,-C)end;return k*2^C%2^32 end;local function E(A,C)A=A%a;C=C%32;local F=y(A,2^C-1)return D(A,C)+lshift(F,32-C)end;local f={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function G(H)return string.gsub(H,".",function(w)return string.format("%02x",string.byte(w))end)end;local function I(J,n)local H=""for K=1,n do local L=J%256;H=string.char(L)..H;J=(J-L)/256 end;return H end;local function M(H,K)local n=0;for K=K,K+3 do n=n*256+string.byte(H,K)end;return n end;local function N(O,P)local Q=64-(P+9)%64;P=I(8*P,8)O=O.."\128"..string.rep("\0",Q)..P;assert(#O%64==0)return O end;local function R(S)S[1]=0x6a09e667;S[2]=0xbb67ae85;S[3]=0x3c6ef372;S[4]=0xa54ff53a;S[5]=0x510e527f;S[6]=0x9b05688c;S[7]=0x1f83d9ab;S[8]=0x5be0cd19;return S end;local function T(O,K,S)local U={}for V=1,16 do U[V]=M(O,K+(V-1)*4)end;for V=17,64 do local g=U[V-15]local W=v(E(g,7),E(g,18),D(g,3))g=U[V-2]U[V]=U[V-16]+W+U[V-7]+v(E(g,17),E(g,19),D(g,10))end;local k,l,w,X,Y,d,Z,_=S[1],S[2],S[3],S[4],S[5],S[6],S[7],S[8]for K=1,64 do local W=v(E(k,2),E(k,13),E(k,22))local a0=v(y(k,l),y(k,w),y(l,w))local a1=W+a0;local a2=v(E(Y,6),E(Y,11),E(Y,25))local a3=v(y(Y,d),y(z(Y),Z))local a4=_+a2+a3+f[K]+U[K]_,Z,d,Y,X,w,l,k=Z,d,Y,X+a4,w,l,k,a4+a1 end;S[1]=y(S[1]+k)S[2]=y(S[2]+l)S[3]=y(S[3]+w)S[4]=y(S[4]+X)S[5]=y(S[5]+Y)S[6]=y(S[6]+d)S[7]=y(S[7]+Z)S[8]=y(S[8]+_)end;local function sha256(O)O=N(O,#O)local S=R({})for K=1,#O,64 do T(O,K,S)end;return G(I(S[1],4)..I(S[2],4)..I(S[3],4)..I(S[4],4)..I(S[5],4)..I(S[6],4)..I(S[7],4)..I(S[8],4))end

local Security = {}

function Security.GenerateSalt(length)
  local salt = ""
  for i=1,(length or 8) do
    salt = salt .. string.char(math.random(33, 127))
  end
  return salt
end

function Security.Hash(input, salt)
  return sha256(input .. (salt or ""))
end

local AES = System.Library.Load("K:/lib/AES")
local Base64 = System.Library.Load("K:/lib/Base64")

function Security.Encrypt(input, key)
  return Base64.encode(AES.encrypt(key, input))
end

function Security.Decrypt(input, key)
  return AES.decrypt(key, Base64.decode(input))
end

function Security.Encode(input)
  return Base64.encode(input)
end

function Security.Decode(input)
  return Base64.decode(input)
end

return Security
