import puppeteer from 'puppeteer';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.join(__dirname, '..', '..');

async function scrapeCommissionMembers(commissionId, commissionName) {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  
  try {
    const url = `https://www.senat.ro/ComponentaComisii.aspx?Zi=&ComisieID=${commissionId}`;
    console.log(`\nFetching ${commissionName}`);
    
    await page.goto(url, {
      waitUntil: 'networkidle0',
      timeout: 30000
    });

    const members = await page.evaluate(() => {
      // First get all the links that point to senator profiles
      const senatorNodes = Array.from(document.querySelectorAll('a[href*="FisaSenator.aspx"]'));
      
      return senatorNodes.map(senatorNode => {
        // Navigate up to find the containing div
        const containerDiv = senatorNode.closest('div:not([class])');
        if (!containerDiv) return null;
        
        // Get the name from the senator link
        const name = senatorNode.textContent?.trim() || '';
        const parlamentarId = senatorNode.href?.match(/ParlamentarID=([^&]+)/)?.[1] || '';
        
        // The role text is usually right after the name in the container
        const textContent = containerDiv.textContent || '';
        const afterName = textContent.split(name)[1] || '';
        const [role] = afterName.split('din').map(s => s.trim());
        
        // Get the start date if it exists
        const dateMatch = afterName.match(/din\s+(\d{2}\.\d{2}\.\d{4})/);
        const startDate = dateMatch ? dateMatch[1] : '';
        
        // Find the party group link in the container
        const partyNode = containerDiv.querySelector('a[href*="ComponentaGrupuri.aspx"]');
        const party = partyNode?.textContent?.replace('grup', '')?.trim() || '';
        const partyId = partyNode?.href?.match(/GrupID=([^&]+)/)?.[1] || '';
        
        console.log(`Found member: ${name}, Role: ${role}, Party: ${party}`);
        
        return {
          name,
          role: role.replace(/\s+/g, ' ').trim(),
          party,
          parlamentarId,
          partyId,
          startDate
        };
      }).filter(member => member && member.name && member.role);
    });

    console.log(`Found ${members.length} members for ${commissionName}`);
    return members;

  } catch (error) {
    console.error(`Error scraping commission ${commissionName}:`, error);
    return [];
  } finally {
    await browser.close();
  }
}

async function main() {
  try {
    // Read the senate_commissions.json file with updated path
    const commissionsPath = path.join(projectRoot, 'public', 'data', 'senate', 'senate_commissions.json');
    const { commissions } = JSON.parse(await fs.readFile(commissionsPath, 'utf-8'));

    const commissionsData = [];

    // Process each commission
    for (const commission of commissions) {
      console.log(`\nProcessing commission: ${commission.name}`);
      
      const members = await scrapeCommissionMembers(commission.official_id, commission.name);
      
      commissionsData.push({
        id: commission.official_id,
        name: commission.name,
        short_name: commission.short_name,
        type: commission.type,
        members
      });

      // Add a delay between requests
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

    // Save everything to a single file with updated path
    const outputPath = path.join(projectRoot, 'public', 'data', 'senate', 'commission_members.json');
    await fs.writeFile(outputPath, JSON.stringify({ commissions: commissionsData }, null, 2));

    console.log('\nScraping completed! Summary:');
    commissionsData.forEach(commission => {
      console.log(`${commission.name}: ${commission.members.length} members`);
    });
  } catch (error) {
    console.error('Error in main process:', error);
  }
}

main();