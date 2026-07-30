function CSGradientDiskClass()
{
   if(this.innerColor == undefined)
   {
      this.innerColor = 16711680;
   }
   if(this.innerAlpha == undefined)
   {
      this.innerAlpha = 80;
   }
   if(this.outerColor == undefined)
   {
      this.outerColor = 16711935;
   }
   if(this.outerAlpha == undefined)
   {
      this.outerAlpha = 40;
   }
   this.update();
}
var p = CSGradientDiskClass.prototype = new MovieClip();
Object.registerClass("CSGradientDisk",CSGradientDiskClass);
p._nP = 10;
p._step = 6.283185307179586 / p._nP;
p._aP = new Array();
p._cP = new Array();
var halfStep = p._step / 2;
var cRad = 100 / Math.cos(halfStep);
var i = 0;
while(i < p._nP)
{
   var aObj = new Object();
   var aAngle = (i + 1) * p._step;
   aObj.x = 100 * Math.cos(aAngle);
   aObj.y = -100 * Math.sin(aAngle);
   p._aP[i] = aObj;
   var cObj = new Object();
   var cAngle = aAngle - halfStep;
   cObj.x = cRad * Math.cos(cAngle);
   cObj.y = (- cRad) * Math.sin(cAngle);
   p._cP[i] = cObj;
   i++;
}
p.update = function()
{
   this.clear();
   this.lineStyle(1,255,0);
   this.beginGradientFill("radial",[this.innerColor,this.outerColor],[this.innerAlpha,this.outerAlpha],[0,255],{matrixType:"box",x:-100,y:-100,w:200,h:200,r:0});
   this.moveTo(this._aP[this._nP - 1].x,this._aP[this._nP - 1].y);
   var i = 0;
   while(i < this._nP)
   {
      this.curveTo(this._cP[i].x,this._cP[i].y,this._aP[i].x,this._aP[i].y);
      i++;
   }
   this.endFill();
};
