function CSPointClass()
{
   this.stop();
}
var p = CSPointClass.prototype = new MovieClip();
Object.registerClass("CS Point",CSPointClass);
p.maxRadius = 150;
p.useHandCursor = false;
p.onPress = function()
{
   this.xOffset = this._parent._xmouse - this._x;
   this.yOffset = this._parent._ymouse - this._y;
   this.onMouseMove = this.onMouseMoveFunc;
};
p.onMouseMoveFunc = function()
{
   var newX = this._parent._xmouse - this.xOffset;
   var newY = this._parent._ymouse - this.yOffset;
   var r = Math.sqrt(newX * newX + newY * newY);
   if(r > this.maxRadius)
   {
      var angle = Math.atan2(newY,newX);
      newX = this.maxRadius * Math.cos(angle);
      newY = this.maxRadius * Math.sin(angle);
   }
   this._x = newX;
   this._y = newY;
   this._parent.update();
   updateAfterEvent();
};
p.onRelease = function()
{
   this.onMouseMove = undefined;
};
p.onRollOver = function()
{
   this._parent.pointActive();
};
p.onRollOut = function()
{
   this._parent.pointInactive();
};
p.onReleaseOutside = function()
{
   this._parent.pointInactive();
   this.onMouseMove = undefined;
};
