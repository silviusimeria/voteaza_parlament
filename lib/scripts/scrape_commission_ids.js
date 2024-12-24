const puppeteer = require('puppeteer');
const fs = require('fs/promises');
const path = require('path');

async function scrapeCommissionIds() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  try {
    await page.goto('https://www.senat.ro/EnumComisii.aspx?Permanenta=1');
    
    // Get all commission links and their IDs
    const commissions = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('#GridViewCom a[href*="ComisieID"]')).map(link => {
        const url = new URL(link.href);
        const comisieId = url.searchParams.get('ComisieID');
        return {
          name: link.textContent.trim(),
          official_id: comisieId,
          type: 'permanent'
        };
      });
    });

    // Read existing JSON file
    const jsonPath = path.join(__dirname, '../../public/data/senate/senate_commissions.json');
    const existingData = JSON.parse(await fs.readFile(jsonPath, 'utf-8'));

    // Update official_ids in existing data
    const updatedCommissions = existingData.commissions.map(comm => {
      const match = commissions.find(c => c.name === comm.name);
      if (match) {
        return { ...comm, official_id: match.official_id };
      }
      return comm;
    });

    // Save updated data
    await fs.writeFile(
      jsonPath,
      JSON.stringify({ commissions: updatedCommissions }, null, 2)
    );

    console.log('Updated commission IDs:');
    updatedCommissions.forEach(c => {
      console.log(`${c.name}: ${c.official_id}`);
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await browser.close();
  }
}

scrapeCommissionIds();