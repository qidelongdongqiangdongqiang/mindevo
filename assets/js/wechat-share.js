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
    return window.location.href.split("#")[0];
  }

  function canonicalShareUrl() {
    return (
      meta('meta[property="og:url"]') ||
      meta('link[rel="canonical"]') ||
      currentUrlForSignature()
    );
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

    if (wx.updateAppMessageShareData) {
      wx.updateAppMessageShareData(data);
    }
    if (wx.updateTimelineShareData) {
      wx.updateTimelineShareData({
        title: data.title,
        link: data.link,
        imgUrl: data.imgUrl,
      });
    }

    // Older WeChat clients still rely on these APIs.
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
        "updateAppMessageShareData",
        "updateTimelineShareData",
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
