// Interactive point-field background. Theme-aware; honours reduced-motion.
//
// Ambient: a field of points drifts, and points near the cursor connect into a
// constellation web. Gather: hold the cursor and nearby points are pulled in and
// absorbed into a growing STAR; at a threshold the star bursts and scatters its
// points back across the field, where they can be gathered again — a continuous
// cycle. New points spawn while you play, up to a hard cap so the page never bogs.
(function(){
  const cv=document.getElementById('dots'); if(!cv) return;
  const ctx=cv.getContext('2d',{alpha:true});
  const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;

  const MAX=2500;                 // hard cap on total points (field + star)
  const NEAR=175, NEAR2=NEAR*NEAR; // cursor influence + web radius
  const ABSORB=18, ABSORB2=ABSORB*ABSORB;
  const BURST=48;                 // star mass at which it explodes
  const WEBCAP=90;                // cap the web to the nearest N points (keeps O(k^2) bounded)

  let W=0,H=0,DPR=1,pts=[],raf=0,frame=0,spin=0;
  const mouse={x:-9999,y:-9999,on:false};
  const star={x:0,y:0,mass:0,r:0};

  function cssvar(n,f){ const v=getComputedStyle(document.documentElement).getPropertyValue(n).trim(); return v||f; }
  function hexToRgb(h){ h=h.replace('#',''); if(h.length===3) h=h.split('').map(c=>c+c).join('');
    const n=parseInt(h,16); return (h.length===6)?[(n>>16)&255,(n>>8)&255,n&255]:[150,120,240]; }
  let RGB=cssvar('--dot','20,28,45');       // "r,g,b" for the field
  let HD=hexToRgb(cssvar('--hd','#6d28d9')); // accent for the star glow
  function readTheme(){ RGB=cssvar('--dot','20,28,45'); HD=hexToRgb(cssvar('--hd','#6d28d9')); }

  function mkpt(x,y,vx,vy){ const z=Math.random();
    return {x:(x==null?Math.random()*W:x), y:(y==null?Math.random()*H:y), z,
      vx:(vx==null?(Math.random()-.5)*(.12+z*.22):vx), vy:(vy==null?(Math.random()-.5)*(.12+z*.22):vy)}; }

  function resize(){
    DPR=Math.min(2,window.devicePixelRatio||1);
    W=cv.clientWidth; H=cv.clientHeight;
    cv.width=Math.floor(W*DPR); cv.height=Math.floor(H*DPR);
    ctx.setTransform(DPR,0,0,DPR,0,0);
    const target=Math.min(MAX, Math.round(W*H/1200)); // starting density; grows via spawn
    pts=[]; for(let i=0;i<target;i++) pts.push(mkpt());
    star.mass=0; star.r=0;
  }

  function explode(){
    const n=star.mass;
    for(let i=0;i<n;i++){ const a=Math.random()*6.283, sp=1.6+Math.random()*3.8;
      pts.push(mkpt(star.x,star.y,Math.cos(a)*sp,Math.sin(a)*sp)); }
    star.mass=0; star.r=0;
  }

  function drawStar(x,y,r,t){ // t = charge 0..1
    const pulse=1+0.12*Math.sin(frame*0.25)*(t>0.75?1:0.3);
    const R=r*pulse, gl=R*3.2;
    const g=ctx.createRadialGradient(x,y,0,x,y,gl);
    g.addColorStop(0,'rgba('+HD[0]+','+HD[1]+','+HD[2]+','+(0.42+0.35*t)+')');
    g.addColorStop(0.5,'rgba('+HD[0]+','+HD[1]+','+HD[2]+','+(0.10+0.10*t)+')');
    g.addColorStop(1,'rgba('+HD[0]+','+HD[1]+','+HD[2]+',0)');
    ctx.beginPath(); ctx.arc(x,y,gl,0,6.283); ctx.fillStyle=g; ctx.fill();
    // spokes
    spin+=0.01; const spokes=6, len=R*(1.5+2.0*t);
    ctx.strokeStyle='rgba(255,244,214,'+(0.35+0.45*t)+')'; ctx.lineWidth=1;
    for(let i=0;i<spokes;i++){ const a=spin+i*(6.283/spokes);
      ctx.beginPath(); ctx.moveTo(x,y); ctx.lineTo(x+Math.cos(a)*len,y+Math.sin(a)*len); ctx.stroke(); }
    // core
    ctx.beginPath(); ctx.arc(x,y,Math.max(1.4,R*0.5),0,6.283);
    ctx.fillStyle='rgba(255,248,226,'+(0.85+0.15*t)+')'; ctx.fill();
  }

  function step(){
    frame++;
    ctx.clearRect(0,0,W,H);

    // spawn new points at an edge while gathering, up to the cap
    if(mouse.on && (frame&1)===0 && pts.length+star.mass<MAX){
      const e=frame%4; let x,y;
      if(e===0){x=Math.random()*W;y=-6;} else if(e===1){x=W+6;y=Math.random()*H;}
      else if(e===2){x=Math.random()*W;y=H+6;} else {x=-6;y=Math.random()*H;}
      pts.push(mkpt(x,y));
    }

    const near=[];
    for(let k=pts.length-1;k>=0;k--){
      const p=pts[k];
      p.x+=p.vx; p.y+=p.vy;
      // scattered (fast) points bleed speed until they settle into ambient drift
      if(p.vx*p.vx+p.vy*p.vy>0.55){ p.vx*=0.955; p.vy*=0.955; }
      if(mouse.on){
        const dx=mouse.x-p.x, dy=mouse.y-p.y, d2=dx*dx+dy*dy;
        if(d2<ABSORB2){ pts.splice(k,1); star.mass++; continue; }   // absorbed into the star
        if(d2<NEAR2){ const d=Math.sqrt(d2)+1, f=(1-d2/NEAR2)*1.5*(0.6+p.z)/d;
          p.vx+=dx*f; p.vy+=dy*f; if(near.length<WEBCAP) near.push(p); }
      }
      if(p.x<-10)p.x=W+10; if(p.x>W+10)p.x=-10; if(p.y<-10)p.y=H+10; if(p.y>H+10)p.y=-10;
      const r=0.6+p.z*1.9, a=0.10+p.z*0.30;
      ctx.beginPath(); ctx.arc(p.x,p.y,r,0,6.283); ctx.fillStyle='rgba('+RGB+','+a+')'; ctx.fill();
    }

    // constellation web — only among the near-cursor subset, so it stays cheap at any cap
    for(let i=0;i<near.length;i++){ const a=near[i];
      for(let j=i+1;j<near.length;j++){ const b=near[j]; const dx=a.x-b.x,dy=a.y-b.y,d2=dx*dx+dy*dy;
        if(d2<NEAR2){ const al=(1-d2/NEAR2)*0.16;
          ctx.beginPath(); ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y);
          ctx.strokeStyle='rgba('+RGB+','+al+')'; ctx.lineWidth=0.6; ctx.stroke(); } } }

    // the star follows the cursor, grows toward its mass, and bursts at the threshold
    if(mouse.on){ star.x+=(mouse.x-star.x)*0.2; star.y+=(mouse.y-star.y)*0.2; }
    if(star.mass>0){
      const tr=Math.sqrt(star.mass)*3.4; star.r+=(tr-star.r)*0.14;
      drawStar(star.x,star.y,star.r,Math.min(1,star.mass/BURST));
      if(star.mass>=BURST) explode();
    }

    raf=requestAnimationFrame(step);
  }

  function stat(){ // reduced-motion: a still field, no gather
    ctx.clearRect(0,0,W,H);
    for(const p of pts){ const r=0.6+p.z*1.9, a=0.10+p.z*0.30;
      ctx.beginPath(); ctx.arc(p.x,p.y,r,0,6.283); ctx.fillStyle='rgba('+RGB+','+a+')'; ctx.fill(); }
  }

  window.addEventListener('resize',()=>{resize(); if(reduce)stat();});
  window.addEventListener('mousemove',e=>{mouse.x=e.clientX;mouse.y=e.clientY;mouse.on=true;});
  window.addEventListener('mouseout',()=>{mouse.on=false;mouse.x=-9999;mouse.y=-9999;});
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change',readTheme);
  resize();
  if(reduce){ stat(); } else { raf=requestAnimationFrame(step); }
})();
