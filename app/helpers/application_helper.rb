module ApplicationHelper
  def color_with_alpha(color, alpha)
    return nil unless color.present?

    # Convert hex to RGB and add alpha
    hex = color.delete("#")
    r, g, b = hex.scan(/../).map(&:hex)
    "rgba(#{r}, #{g}, #{b}, #{alpha})"
  end

  def number_to_percentage(number, options = {})
    precision = options[:precision] || 0
    format("%.#{precision}f%%", number)
  end

  def research_sections
      [
        {
          title: "1. Înțelegere Juridică",
          items: [
            "Cunoștințe de bază despre drept constituțional",
            "Înțelegerea procedurilor legislative",
            "Capacitatea de a analiza și redacta legi"
          ]
        },
        {
          title: "2. Abilități de Comunicare",
          items: [
            "Capacitate de exprimare clară în public",
            "Comunicare eficientă în scris",
            "Interacțiune constructivă cu alegătorii",
            "Relație profesională cu mass-media"
          ]
        },
        {
          title: "3. Expertiză în Politici Publice",
          items: [
            "Înțelegerea procesului de elaborare a politicilor publice",
            "Cunoștințe în domenii specifice de politici",
            "Competențe în analiza bugetară și financiară",
            "Înțelegere economică fundamentală"
          ]
        },
        {
          title: "4. Leadership și Management",
          items: [
            "Capacitate dovedită de luare a deciziilor",
            "Experiență în conducerea echipelor",
            "Abilități de negociere și mediere",
            "Construirea consensului între părți diverse",
            "Gestionarea eficientă a timpului și resurselor"
          ]
        },
        {
          title: "5. Servicii pentru Alegători",
          items: [
            "Abilități demonstrate de rezolvare a problemelor",
            "Practică în ascultarea activă a cetățenilor",
            "Înțelegerea aprofundată a problemelor locale",
            "Capacitatea de a echilibra interesele locale cu cele naționale"
          ]
        }
      ]
    end
end
