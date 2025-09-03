// Minimal headless Selenium check against /health
const { Builder, By } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

(async () => {
  let driver;
  try {
    const opts = new chrome.Options().addArguments('--headless=new');
    driver = await new Builder()
      .forBrowser('chrome')
      .usingServer('http://localhost:4444/wd/hub') // selenium service
      .setChromeOptions(opts)
      .build();

    await driver.get('http://localhost:3000/health');
    const body = await driver.findElement(By.css('body')).getText();
    if (!/ok/i.test(body)) {
      console.error('Health endpoint did not return ok');
      process.exit(1);
    }
    console.log('Selenium health check OK');
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(2);
  } finally {
    if (driver) await driver.quit();
  }
})();
