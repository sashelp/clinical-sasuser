/* 为宏程序详情页的所有代码块添加复制按钮：点击后短暂显示“已复制”，随后回弹 */
(function () {
  var blocks = document.querySelectorAll('pre.code');

  function legacyCopy(text) {
    var area = document.createElement('textarea');
    area.value = text;
    area.style.position = 'fixed';
    area.style.top = '0';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.focus();
    area.select();
    var ok = false;
    try {
      ok = document.execCommand('copy');
    } catch (e) {
      ok = false;
    }
    document.body.removeChild(area);
    return ok;
  }

  Array.prototype.forEach.call(blocks, function (pre) {
    var wrapper = document.createElement('div');
    wrapper.className = 'code-block';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'copy-btn';
    btn.textContent = '复制';
    btn.setAttribute('aria-live', 'polite');
    wrapper.appendChild(btn);

    var timer = null;

    function flash(text, stateClass) {
      if (timer) {
        clearTimeout(timer);
      }
      btn.textContent = text;
      btn.className = 'copy-btn ' + stateClass;
      timer = setTimeout(function () {
        btn.textContent = '复制';
        btn.className = 'copy-btn';
        timer = null;
      }, 1500);
    }

    btn.addEventListener('click', function () {
      var text = pre.textContent;

      var success = function () {
        flash('已复制', 'is-copied');
      };

      var failure = function () {
        flash('复制失败', 'is-failed');
      };

      /* 优先使用同步复制，兼容 file:// 与本地静态服务 */
      if (legacyCopy(text)) {
        success();
      } else if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(success, failure);
      } else {
        failure();
      }
    });
  });
})();
