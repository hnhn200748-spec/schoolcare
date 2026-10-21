(()=> {
'use strict';
const KEY='schoolcareRequestsV1', AUTH='schoolcareStaffSession';
const statuses=['รอตรวจสอบ','กำลังดำเนินการ','ซ่อมเสร็จแล้ว','ไม่สามารถซ่อมได้'];
const $=id=>document.getElementById(id);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const read=()=>{try{const x=JSON.parse(localStorage.getItem(KEY)||'[]');return Array.isArray(x)?x:[]}catch{return []}};
const save=x=>localStorage.setItem(KEY,JSON.stringify(x));
const badge=s=>`<span class="status ${s==='ซ่อมเสร็จแล้ว'?'done':s==='กำลังดำเนินการ'?'repairing':s==='ไม่สามารถซ่อมได้'?'unrepairable':'pending'}">${esc(s||'รอตรวจสอบ')}</span>`;
const toast=(m,err=false)=>{const t=$('toast');if(t){t.textContent=m;t.className='toast show'+(err?' error':'');setTimeout(()=>t.className='toast',3000)}};
const isStaff=()=>sessionStorage.getItem(AUTH)==='1';
const login=$('loginForm');
if(login) login.addEventListener('submit',e=>{e.preventDefault();const u=$('username')?.value.trim(),p=$('password')?.value;
 // Demo credentials only; static hosting cannot securely authenticate staff.
 if(u==='admin'&&p==='schoolcare123'){sessionStorage.setItem(AUTH,'1');location.href='dashboard.html'}
 else toast('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง (ทดลองใช้ admin / schoolcare123)',true);
});
const list=$('rows');
if(list){
 if(!isStaff()){location.href='login.html';return;}
 const a=read().sort((x,y)=>new Date(y.created||0)-new Date(x.created||0));
 if($('total'))$('total').textContent=a.length;
 if($('pending'))$('pending').textContent=a.filter(x=>!['ซ่อมเสร็จแล้ว','ไม่สามารถซ่อมได้'].includes(x.status)).length;
 if($('done'))$('done').textContent=a.filter(x=>x.status==='ซ่อมเสร็จแล้ว').length;
 list.innerHTML=a.length?`<div class="table-wrap"><table><thead><tr><th>เลขที่</th><th>หัวข้อ</th><th>ผู้แจ้ง</th><th>สถานะ</th><th>จัดการ</th></tr></thead><tbody>${a.map(x=>`<tr><td><strong>${esc(x.id)}</strong></td><td>${esc(x.subject)}</td><td>${esc(x.reporter)}</td><td><select class="status-select" data-id="${esc(x.id)}">${statuses.map(s=>`<option ${s===(x.status||'รอตรวจสอบ')?'selected':''}>${s}</option>`).join('')}</select></td><td><a href="detail.html?number=${encodeURIComponent(x.id)}">รายละเอียด</a></td></tr>`).join('')}</tbody></table></div>`:'<div class="empty-state"><div class="empty-icon">▦</div><h3>ยังไม่มีคำขอแจ้งซ่อม</h3><p>คำขอที่ส่งจากหน้าแจ้งซ่อมบนเบราว์เซอร์นี้จะแสดงที่นี่</p><a class="btn btn-secondary" href="report.html">＋ แจ้งซ่อมอุปกรณ์</a></div>';
 list.addEventListener('change',e=>{const id=e.target.dataset.id;if(!id)return;const xs=read(),r=xs.find(x=>String(x.id)===id);if(r){r.status=e.target.value;save(xs);toast('บันทึกสถานะแล้ว');}});
}
const detail=$('staffDetail');
if(detail){
 if(!isStaff()){location.href='login.html';return;}
 const id=new URLSearchParams(location.search).get('number'),r=read().find(x=>String(x.id)===id);
 if(!r){detail.innerHTML='<div class="empty-state"><h3>ไม่พบคำขอ</h3><p>ตรวจสอบหมายเลขคำขออีกครั้ง</p></div>';return;}
 detail.innerHTML=`<div class="top-actions"><div><span class="section-kicker">REQUEST DETAIL</span><h2>${esc(r.id)}</h2></div>${badge(r.status)}</div><div class="detail-grid">${[['หัวข้อ',r.subject],['ผู้แจ้ง',r.reporter],['เบอร์โทร',r.phone],['ประเภท',r.category],['สถานที่',r.location],['ความเร่งด่วน',r.priority],['วันที่แจ้ง',r.created?new Date(r.created).toLocaleString('th-TH'):'-']].map(([k,v])=>`<div class="detail-cell"><small>${k}</small><b>${esc(v||'-')}</b></div>`).join('')}</div><div class="detail-cell" style="margin:14px 0"><small>รายละเอียดปัญหา</small><p>${esc(r.details||'-')}</p></div><label class="field">เปลี่ยนสถานะ<select id="detailStatus" class="status-select">${statuses.map(s=>`<option ${s===(r.status||'รอตรวจสอบ')?'selected':''}>${s}</option>`).join('')}</select></label><button class="btn btn-primary" id="saveStatus" style="margin-top:14px">บันทึกสถานะ</button><p id="saveMessage" aria-live="polite"></p>`;
 $('saveStatus').addEventListener('click',()=>{const xs=read(),x=xs.find(y=>String(y.id)===id);if(x){x.status=$('detailStatus').value;save(xs);$('saveMessage').textContent='บันทึกสถานะเรียบร้อยแล้ว';toast('บันทึกสถานะแล้ว')}});
}
const logout=$('logoutBtn');if(logout)logout.addEventListener('click',()=>{sessionStorage.removeItem(AUTH);location.href='login.html'});
document.querySelectorAll('.year').forEach(e=>e.textContent=new Date().getFullYear());
})();