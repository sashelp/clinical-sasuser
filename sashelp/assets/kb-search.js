/* 知识库首页搜索：按问题、短回答、类别和正文摘要过滤表格行 */
(function () {
  var input = document.getElementById('kb-search-input');
  if (!input) { return; }
  var status = document.getElementById('kb-search-status');
  var rows = Array.prototype.slice.call(document.querySelectorAll('.kb-table tbody tr[data-slug]'));
  var meta = window.KB_INDEX || {};
  var total = rows.length;

  function norm(s) { return String(s || '').toLowerCase(); }

  function haystack(row) {
    var m = meta[row.getAttribute('data-slug')] || {};
    return norm(row.textContent + ' ' + (m.t || '') + ' ' + (m.d || '') + ' ' + (m.c || '') + ' ' + (m.k || ''));
  }

  function apply() {
    var q = norm(input.value).trim();
    var shown = 0;
    rows.forEach(function (row) {
      var hit = !q || haystack(row).indexOf(q) >= 0;
      row.style.display = hit ? '' : 'none';
      if (hit) { shown++; }
    });
    status.textContent = q ? ('命中 ' + shown + ' / ' + total + ' 条') : '';
  }

  input.addEventListener('input', apply);
  input.addEventListener('change', apply);
  input.addEventListener('search', apply);
  input.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { input.value = ''; apply(); }
  });
  apply();
})();
