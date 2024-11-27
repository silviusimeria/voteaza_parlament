# Romanian Elections Map

An open source web application that visualizes Romanian election candidates across counties. Built with Ruby on Rails 8 and Leaflet.js.

## Features
- Interactive map of Romanian counties
- Candidate information for Senate and Deputy Chamber
- Party affiliations and candidate details
- Administrative interface for data management
- PDF import functionality for candidate lists

## Technology Stack
- Ruby 3.3.0
- Rails 8.0
- SQLite
- Leaflet.js for map visualization
- ActiveAdmin for backend management
- Tailwind CSS for styling

## Getting Started

### Prerequisites
- Ruby 3.3.0
- Rails 8.0
- SQLite3

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/election_map
   cd election_map
   ```

2. Install dependencies
   ```bash
   bundle install
   ```

3. Set up environment variables in `.env`:
   ```
   ADMIN_EMAIL=your_email@example.com
   ADMIN_PASSWORD=your_secure_password
   ```

4. Set up database
   ```bash
   rails db:migrate
   rails db:seed
   ```

5. Start the server
   ```bash
   rails server
   ```

## Contributing
Contributions are welcome! Please feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

### How to Contribute
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Contact & Support
- Email: trickystyle07@gmail.com
- Issues: Please use the GitHub issues tab for bug reports and feature requests

## License
This project is licensed WTFPL. Check LICENCE file for details.