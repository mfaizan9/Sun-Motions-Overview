var p = CelestialSphereClass.prototype;
p.screenToHorizon = function(sp, hp)
{
   this.StoMH(sp,hp);
   hp.az = (360 - hp.az * 57.29577951308232) % 360;
   hp.alt *= 57.29577951308232;
};
p.screenToCelestial = function(sp, cp)
{
   var hp = new Object();
   this.StoMH(sp,hp);
   this.MHtoC(hp,cp);
   cp.ra *= 3.819718634205488;
   cp.dec *= 57.29577951308232;
};
p.toScreen = function(up, sp)
{
   var pt = new Object();
   this.parsePointInput(up,pt);
   if(pt.sys == 0 || pt.sys == -1)
   {
      this.WtoSz(pt,sp);
   }
   else if(pt.sys == 1)
   {
      this.CtoSz(pt,sp);
   }
   else
   {
      sp.x = null;
      sp.y = null;
      sp.z = null;
   }
};
p.pointToHorizon = function(up, hp)
{
   var pt = {};
   this.parsePointInput(up,pt);
   if(pt.sys == 0 || pt.sys == -1)
   {
      var sa = pt.z / pt.r;
      if(sa < -1)
      {
         sa = -1;
      }
      else if(sa > 1)
      {
         sa = 1;
      }
      hp.az = this.mod(-57.29577951308232 * Math.atan2(pt.y,pt.x),360);
      hp.alt = 57.29577951308232 * Math.asin(sa);
      hp.r = pt.r;
   }
   else if(pt.sys == 1)
   {
      var hpt = {};
      this.CtoW(pt,hpt);
      var sa = hpt.z / pt.r;
      if(sa < -1)
      {
         sa = -1;
      }
      else if(sa > 1)
      {
         sa = 1;
      }
      hp.az = this.mod(-57.29577951308232 * Math.atan2(hpt.y,hpt.x),360);
      hp.alt = 57.29577951308232 * Math.asin(sa);
      hp.r = pt.r;
   }
   else
   {
      hp.az = null;
      hp.alt = null;
      hp.r = null;
   }
};
p.pointToCelestial = function(up, cp)
{
   var pt = {};
   this.parsePointInput(up,pt);
   if(pt.sys == 0 || pt.sys == -1)
   {
      var cpt = {};
      this.WtoC(pt,cpt);
      var sd = cpt.z / pt.r;
      if(sd > 1)
      {
         sd = 1;
      }
      else if(sd < -1)
      {
         sd = -1;
      }
      cp.ra = this.mod(3.819718634205488 * Math.atan2(cpt.y,cpt.x),24);
      cp.dec = 57.29577951308232 * Math.asin(sd);
      cp.r = pt.r;
   }
   else if(pt.sys == 1)
   {
      var sd = pt.z / pt.r;
      if(sd > 1)
      {
         sd = 1;
      }
      else if(sd < -1)
      {
         sd = -1;
      }
      cp.ra = this.mod(3.819718634205488 * Math.atan2(pt.y,pt.x),24);
      cp.dec = 57.29577951308232 * Math.asin(sd);
      cp.r = pt.r;
   }
   else
   {
      cp.ra = null;
      cp.dec = null;
      cp.r = null;
   }
};
p.parsePointInput = function(p1, p2)
{
   if(p1.az != undefined && p1.alt != undefined)
   {
      p2.sys = 0;
      p2.system = "horizon";
      var r = 1;
      if(p1.r != undefined)
      {
         r = p1.r;
      }
      var d = r * Math.cos(p1.alt * 0.017453292519943295);
      p2.x = d * Math.cos(p1.az * 0.017453292519943295);
      p2.y = d * Math.sin((- p1.az) * 0.017453292519943295);
      p2.z = r * Math.sin(p1.alt * 0.017453292519943295);
      p2.r = Math.abs(r);
   }
   else if(p1.ra != undefined && p1.dec != undefined)
   {
      p2.sys = 1;
      p2.system = "celestial";
      var r = 1;
      if(p1.r != undefined)
      {
         r = p1.r;
      }
      var d = r * Math.cos(p1.dec * 0.017453292519943295);
      p2.x = d * Math.cos(p1.ra * 0.2617993877991494);
      p2.y = d * Math.sin(p1.ra * 0.2617993877991494);
      p2.z = r * Math.sin(p1.dec * 0.017453292519943295);
      p2.r = Math.abs(r);
   }
   else if(p1.x != undefined && p1.y != undefined && p1.z != undefined)
   {
      if(p1.system == "horizon")
      {
         p2.sys = 0;
         p2.system = "horizon";
      }
      else if(p1.system == "celestial")
      {
         p2.sys = 1;
         p2.system = "celestial";
      }
      else
      {
         p2.sys = -1;
         p2.system = "unknown";
      }
      p2.x = p1.x;
      p2.y = p1.y;
      p2.z = p1.z;
      p2.r = Math.sqrt(p2.x * p2.x + p2.y * p2.y + p2.z * p2.z);
      if(p2.r < 1.000001 && p2.r > 0.999999)
      {
         p2.r = 1;
      }
   }
   else
   {
      p2.sys = null;
      p2.system = null;
      p2.x = null;
      p2.y = null;
      p2.z = null;
      p2.r = null;
   }
};
p.WtoS = function(p, sp)
{
   var c = this._c;
   sp.x = p.x * c.a0 + p.y * c.a1;
   sp.y = p.x * c.a3 + p.y * c.a4 + p.z * c.a5;
};
p.WtoSz = function(p, sp)
{
   var c = this._c;
   sp.x = p.x * c.a0 + p.y * c.a1;
   sp.y = p.x * c.a3 + p.y * c.a4 + p.z * c.a5;
   sp.z = p.x * c.a6 + p.y * c.a7 + p.z * c.a8;
};
p.CtoS = function(p, sp)
{
   var c = this._c;
   sp.x = p.x * c.b0 + p.y * c.b1 + p.z * c.b2;
   sp.y = p.x * c.b3 + p.y * c.b4 + p.z * c.b5;
};
p.CtoSz = function(p, sp)
{
   var c = this._c;
   sp.x = p.x * c.b0 + p.y * c.b1 + p.z * c.b2;
   sp.y = p.x * c.b3 + p.y * c.b4 + p.z * c.b5;
   sp.z = p.x * c.b6 + p.y * c.b7 + p.z * c.b8;
};
p.CtoW = function(p, wp)
{
   var c = this._c;
   wp.x = p.x * c.m0 + p.y * c.m1 + p.z * c.m2;
   wp.y = p.x * c.m3 + p.y * c.m4;
   wp.z = p.x * c.m6 + p.y * c.m7 + p.z * c.m8;
};
p.WtoC = function(p, cp)
{
   var c = this._c;
   cp.x = p.x * c.m0 + p.y * c.m3 + p.z * c.m6;
   cp.y = p.x * c.m1 + p.y * c.m4 + p.z * c.m7;
   cp.z = p.x * c.m2 + p.z * c.m8;
};
p.CtoMH = function(cp, hp)
{
   var sd = Math.sin(cp.dec);
   var cd = Math.cos(cp.dec);
   var sl = Math.sin(this._lat);
   var cl = Math.cos(this._lat);
   var h = this._sTime - cp.ra;
   var ch = Math.cos(h);
   var caz = sd * cl - cd * ch * sl;
   var saz = cd * Math.sin(h);
   if(caz == 0)
   {
      hp.az = 0;
   }
   else
   {
      hp.az = this.mod(Math.atan2(saz,caz),6.283185307179586);
   }
   hp.alt = Math.asin(sd * sl + cd * ch * cl);
};
p.MHtoC = function(hp, cp)
{
   var salt = Math.sin(hp.alt);
   var calt = Math.cos(hp.alt);
   var saz = Math.sin(hp.az);
   var caz = Math.cos(hp.az);
   var slat = Math.sin(this._lat);
   var clat = Math.cos(this._lat);
   var sh = calt * saz;
   var ch = salt * clat - calt * slat * caz;
   if(ch == 0)
   {
      cp.ra = 0;
   }
   else
   {
      cp.ra = this.mod(this._sTime - Math.atan2(sh,ch),6.283185307179586);
   }
   cp.dec = Math.asin(salt * slat + calt * caz * clat);
};
p.StoMH = function(sp, hp)
{
   var M = Math;
   var d = M.sqrt(sp.x * sp.x + sp.y * sp.y) / this._c.r;
   if(d > 1)
   {
      d = 1;
   }
   var b = M.asin(d);
   var A = M.atan2(sp.x,- sp.y);
   if(this._phi == 1.5707963267948966)
   {
      hp.alt = 1.5707963267948966 - b;
      hp.az = this._theta + 3.141592653589793 - A;
   }
   else if(this._phi == -1.5707963267948966)
   {
      hp.alt = -1.5707963267948966 + b;
      hp.az = this._theta + A;
   }
   else
   {
      var c = 1.5707963267948966 - this._phi;
      var cc = M.cos(c);
      var sc = M.sin(c);
      var cb = M.cos(b);
      var sb = M.sin(b);
      var ca = cb * cc + sb * sc * M.cos(A);
      hp.alt = 1.5707963267948966 - M.acos(ca);
      hp.az = this._theta + M.atan2(sb * M.sin(A),(cb - ca * cc) / sc);
   }
   hp.az = this.mod(hp.az,6.283185307179586);
};
p.doA = function()
{
   var c = this._c;
   var ct = Math.cos(this._theta);
   var st = Math.sin(this._theta);
   var cp = Math.cos(this._phi);
   var sp = Math.sin(this._phi);
   c.a0 = (- c.r) * st;
   c.a1 = c.r * ct;
   c.a3 = c.r * ct * sp;
   c.a4 = c.r * st * sp;
   c.a5 = (- c.r) * cp;
   c.a6 = c.r * ct * cp;
   c.a7 = c.r * st * cp;
   c.a8 = c.r * sp;
   this._aVer++;
};
p.doM = function()
{
   var c = this._c;
   c.m2 = Math.cos(this._lat);
   c.m3 = Math.sin(this._sTime);
   c.m4 = - Math.cos(this._sTime);
   c.m8 = Math.sin(this._lat);
   c.m0 = c.m4 * c.m8;
   c.m1 = (- c.m3) * c.m8;
   c.m6 = (- c.m2) * c.m4;
   c.m7 = c.m2 * c.m3;
};
p.doB = function()
{
   var c = this._c;
   c.b0 = c.a0 * c.m0 + c.a1 * c.m3;
   c.b1 = c.a0 * c.m1 + c.a1 * c.m4;
   c.b2 = c.a0 * c.m2;
   c.b3 = c.a3 * c.m0 + c.a4 * c.m3 + c.a5 * c.m6;
   c.b4 = c.a3 * c.m1 + c.a4 * c.m4 + c.a5 * c.m7;
   c.b5 = c.a3 * c.m2 + c.a5 * c.m8;
   c.b6 = c.a6 * c.m0 + c.a7 * c.m3 + c.a8 * c.m6;
   c.b7 = c.a6 * c.m1 + c.a7 * c.m4 + c.a8 * c.m7;
   c.b8 = c.a6 * c.m2 + c.a8 * c.m8;
   this._bVer++;
};
