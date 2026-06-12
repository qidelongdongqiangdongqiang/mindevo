(function () {
  const config = window.MindEvoTrackingConfig || {};

  if (config.enabled === false) return;

  const pagePath = window.location.pathname;
  const pageTitle = document.title;
  const sentScrollDepths = new Set();

  const cleanText = (value) => (value || "").replace(/\s+/g, " ").trim().slice(0, 80);

  const loadScript = (src) => {
    const script = document.createElement("script");
    script.async = true;
    script.src = src;
    document.head.appendChild(script);
  };

  if (config.ga4MeasurementId) {
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () { window.dataLayer.push(arguments); };
    loadScript("https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(config.ga4MeasurementId));
    window.gtag("js", new Date());
    window.gtag("config", config.ga4MeasurementId, {
      page_title: pageTitle,
      page_path: pagePath
    });
  }

  if (config.baiduTongjiId) {
    window._hmt = window._hmt || [];
    loadScript("https://hm.baidu.com/hm.js?" + encodeURIComponent(config.baiduTongjiId));
  }

  const sendEvent = (name, params) => {
    const payload = Object.assign({
      page_path: pagePath,
      page_title: pageTitle
    }, params || {});

    if (config.debug) {
      console.info("[MindEvo analytics]", name, payload);
    }

    if (typeof window.gtag === "function" && config.ga4MeasurementId) {
      window.gtag("event", name, payload);
    }

    if (window._hmt && config.baiduTongjiId) {
      window._hmt.push([
        "_trackEvent",
        payload.category || "engagement",
        name,
        payload.label || payload.link_text || pagePath
      ]);
    }
  };

  const classifyLink = (link) => {
    const href = link.getAttribute("href") || "";
    const absoluteHref = link.href || href;
    const text = cleanText(link.dataset.trackLabel || link.textContent || link.getAttribute("aria-label"));
    const params = {
      link_url: absoluteHref,
      link_text: text,
      category: "link"
    };

    if (href.startsWith("tel:")) return ["click_phone", Object.assign(params, { category: "lead" })];
    if (href.includes("contact")) return ["click_contact", Object.assign(params, { category: "lead" })];
    if (href.includes("open-programs")) return ["click_open_programs", Object.assign(params, { category: "admission" })];
    if (href.includes("spectrum-ai")) return ["click_spectrum_ai", Object.assign(params, { category: "admission" })];
    if (href.includes("survival-expedition")) return ["click_survival_expedition", Object.assign(params, { category: "admission" })];
    if (href.startsWith("#")) return ["click_anchor", params];
    if (absoluteHref && link.hostname && link.hostname !== window.location.hostname) return ["click_outbound", params];

    return ["click_internal", params];
  };

  document.addEventListener("click", (event) => {
    const tracked = event.target.closest("[data-track-event]");
    if (tracked) {
      sendEvent(tracked.dataset.trackEvent, {
        category: tracked.dataset.trackCategory || "custom",
        label: tracked.dataset.trackLabel || cleanText(tracked.textContent)
      });
      return;
    }

    const link = event.target.closest("a[href]");
    if (!link) return;
    const [name, params] = classifyLink(link);
    sendEvent(name, params);
  });

  const updateScrollDepth = () => {
    const doc = document.documentElement;
    const scrollable = doc.scrollHeight - window.innerHeight;
    if (scrollable <= 0) return;

    const depth = Math.round((window.scrollY / scrollable) * 100);
    [50, 90].forEach((target) => {
      if (depth >= target && !sentScrollDepths.has(target)) {
        sentScrollDepths.add(target);
        sendEvent("scroll_depth", {
          category: "engagement",
          label: String(target),
          percent_scrolled: target
        });
      }
    });
  };

  window.addEventListener("scroll", updateScrollDepth, { passive: true });
  window.addEventListener("load", updateScrollDepth);

  if ("IntersectionObserver" in window) {
    const observedSections = [
      ["#contact", "view_contact"],
      [".contact-page", "view_contact"],
      [".open-programs-list", "view_open_programs"],
      [".signup-section", "view_signup"]
    ];

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        const eventName = entry.target.dataset.analyticsView;
        if (!eventName) return;
        sendEvent(eventName, {
          category: "section",
          label: entry.target.id || entry.target.className
        });
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.35 });

    observedSections.forEach(([selector, eventName]) => {
      document.querySelectorAll(selector).forEach((section) => {
        section.dataset.analyticsView = eventName;
        observer.observe(section);
      });
    });
  }

  window.MindEvoAnalytics = {
    track: sendEvent
  };
})();
