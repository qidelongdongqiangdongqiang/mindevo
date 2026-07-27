(function () {
  "use strict";

  var ua = navigator.userAgent || "";
  if (!/MicroMessenger/i.test(ua)) return;

  function meta(selector) {
    var node = document.querySelector(selector);
    return node ? (node.getAttribute("content") || node.getAttribute("href") || "").trim() : "";
  }

  function absoluteUrl(value) {
    if (!value) return "";
    try {
      return new URL(value, window.location.href).href;
    } catch (_) {
      return "";
    }
  }

  function currentUrlForSignature() {
    // WeChat may append tracking params (e.g. ?from=singlemessage) to the
    // address bar when the page is opened from a chat link. We sign the
    // canonical URL (og:url / canonical link) instead of the raw current URL,
    // because WeChat's signature verification uses the canonical page URL in
    // those scenarios. The share link is also set to the same canonical URL.
    return (
      meta('meta[property="og:url"]') ||
      meta('link[rel="canonical"]') ||
      window.location.href.split("#")[0]
    );
  }

  function canonicalShareUrl() {
    return currentUrlForSignature();
  }

  function shareData() {
    return {
      title: meta('meta[property="og:title"]') || document.title,
      desc: meta('meta[property="og:description"]') || meta('meta[name="description"]') || "",
      link: absoluteUrl(canonicalShareUrl()),
      imgUrl: absoluteUrl(meta('meta[property="og:image"]')),
    };
  }

  function applyShareData() {
    if (!window.wx) return;
    var data = shareData();
    if (!data.link || !data.imgUrl) return;

    // Use the legacy share APIs: they have the broadest compatibility across
    // WeChat service accounts and avoid the "function not implement" errors
    // seen with updateAppMessageShareData / updateTimelineShareData on some
    // accounts and WeChat client versions.
    if (wx.onMenuShareAppMessage) {
      wx.onMenuShareAppMessage(data);
    }
    if (wx.onMenuShareTimeline) {
      wx.onMenuShareTimeline({
        title: data.title,
        link: data.link,
        imgUrl: data.imgUrl,
      });
    }
  }

  function configureWeChat(signature) {
    if (!window.wx || !signature || !signature.ok) return;
    wx.config({
      debug: false,
      appId: signature.appId,
      timestamp: Number(signature.timestamp),
      nonceStr: signature.nonceStr,
      signature: signature.signature,
      jsApiList: [
        "onMenuShareAppMessage",
        "onMenuShareTimeline",
      ],
    });
    wx.ready(applyShareData);
    wx.error(function (err) {
      if (window.console && console.warn) {
        console.warn("WeChat share config failed", err);
      }
    });
  }

  function init() {
    if (!window.wx || !window.fetch) return;
    var api = "/api/wechat-js-signature/sign?url=" + encodeURIComponent(currentUrlForSignature());
    fetch(api, { credentials: "same-origin" })
      .then(function (response) {
        if (!response.ok) throw new Error("signature request failed");
        return response.json();
      })
      .then(configureWeChat)
      .catch(function (err) {
        if (window.console && console.warn) {
          console.warn("WeChat share signature unavailable", err);
        }
      });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
