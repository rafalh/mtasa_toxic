-- translated some delphi code from{cybermoon.w.interia.pl}

function toint(n)
    local s = tostring(n)
    local i, j = s:find('%.')
    if i then
        return tonumber(s:sub(1, i-1))
    else
        return n
    end
end

function rang(x)
local a,b=0,0
    b= x / 360
    a= 360 * (b - toint(b))
    if (a < 0) then a=a+360 end
    return a
end


function jd(r,m,d)
local a,b,c,e=0,0,0,0

a=4716+r+toint((m+9)/12)
b=1729279.5+367*r+toint(275*m/9)-toint(7*a/4)+d
c=toint((a+83)/100)
e=toint(3*(c+1)/4)
return (b+38-e)
end

function faza(Rok, Miesiac, Dzien, godzina, minuta, sekunda)
local A,b,phi1,phi2,jdp,tzd,elm,ams,aml,asd

    if (Miesiac > 2) then
        Miesiac= Miesiac
        Rok= Rok
        end
    if Miesiac <= 2 then
    Miesiac= Miesiac + 12
    Rok= Rok - 1
    end
    A= toint(Rok / 100)
    b= 2 - A + toint(A / 4)
    jdp= toint(365.25 * (Rok + 4716)) + toint(30.6001 * (Miesiac + 1)) + Dzien + b +((godzina + minuta / 60 + sekunda / 3600) / 24) - 1524.5
	jdp=jdp
tzd= (jdp - 2451545) / 36525
elm= rang(297.8502042 + 445267.1115168 * tzd - (0.00163 * tzd * tzd) + tzd*tzd*tzd / 545868 - (tzd*tzd*tzd*tzd) / 113065000)
ams= rang(357.5291092 + 35999.0502909 * tzd - 0.0001536 * tzd * tzd + tzd*tzd*tzd / 24490000)
aml= rang(134.9634114 + 477198.8676313 * tzd - 0.008997 * tzd * tzd + tzd*tzd*tzd / 69699 - (tzd*tzd*tzd*tzd) / 14712000)
asd= 180 - elm -   (6.289 * math.sin((3.1415926535 / 180) * ((aml)))) + (2.1 * math.sin((3.1415926535 / 180) * ((ams)))) -
                    (1.274 * math.sin((3.1415926535 / 180) * (((2 * elm) - aml)))) - (0.658 * math.sin((3.1415926535 / 180) * ((2 * elm)))) -
                    (0.214 * math.sin((3.1415926535 / 180) * ((2 * aml)))) - (0.11 * math.sin((3.1415926535 / 180) * ((elm))))
				
phi1= ((1 + math.cos((3.1415926535 / 180) * (asd))) / 2)

tzd= (jdp + (0.5 / 2.4) - 2451545) / 36525
elm= rang(297.8502042 + 445267.1115168 * tzd - (0.00163 * tzd * tzd) + tzd*tzd*tzd / 545868 - (tzd*tzd*tzd*tzd) / 113065000)
ams= rang(357.5291092 + 35999.0502909 * tzd - 0.0001536 * tzd * tzd + tzd*tzd*tzd / 24490000)
aml= rang(134.9634114 + 477198.8676313 * tzd - 0.008997 * tzd * tzd + tzd*tzd*tzd / 69699 - (tzd*tzd*tzd*tzd) / 14712000)
asd= 180 - elm -   (6.289 * math.sin((3.1415926535 / 180) * ((aml)))) + (2.1 * math.sin((3.1415926535 / 180) * ((ams)))) -
                    (1.274 * math.sin((3.1415926535 / 180) * (((2 * elm) - aml)))) - (0.658 * math.sin((3.1415926535 / 180) * ((2 * elm)))) -
                    (0.214 * math.sin((3.1415926535 / 180) * ((2 * aml)))) - (0.11 * math.sin((3.1415926535 / 180) * ((elm))))
				
phi2= ((1 + math.cos((3.1415926535 / 180) * (asd))) / 2)

if (phi2-phi1)<0 then phi1=-1*phi1 end
phi1=phi1*100
--outputChatBox('Original phase'..phi1)
local compFaza=(jd(Rok,Miesiac,Dzien)/29.5305902778)-0.3033
compFaza=compFaza-toint(compFaza)
compFaza=((compFaza*2)*100)
if compFaza>100 then compFaza=100-compFaza end
--outputChatBox('Corectional phase'..compFaza)
if (phi1>0) and (compFaza<0) then phi1=-phi1 end
if (phi1<0) and (compFaza>0) then phi1=-phi1 end

return phi1
end

function getCurrentMoonPhase()

local czas = getRealTime()
local obecny ={}
obecny.R=czas.year+1900
obecny.M=czas.month+1
obecny.D=czas.monthday
obecny.G=czas.hour
obecny.Min=czas.minute
obecny.S=czas.second

obecny.faza=faza(obecny.R,obecny.M,obecny.D,obecny.G,obecny.Min,obecny.S)
--   0-100   -->  -100-0
if obecny.faza>=0 then return obecny.faza/10 else
if obecny.faza<0 then return (100+(100+obecny.faza))/10 end end
--  0-20
end
