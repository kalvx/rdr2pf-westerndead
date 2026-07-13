
function esc(v){return String(v??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[m]));}
function filterTable(inputId, tableId){
 const q=document.getElementById(inputId).value.toLowerCase();
 document.querySelectorAll(`#${tableId} tbody tr`).forEach(r=>r.style.display=r.innerText.toLowerCase().includes(q)?"":"none");
}
