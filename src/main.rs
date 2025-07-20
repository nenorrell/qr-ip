use qrcode::QrCode;
use qrcode::render::svg;
use tiny_http::{Server, Response, Header};
use std::net::{UdpSocket, IpAddr};

fn discover_ip() -> IpAddr {
    let sock = UdpSocket::bind("0.0.0.0:0").expect("bind socket");
    if sock.connect("1.1.1.1:80").is_ok() {
        if let Ok(addr) = sock.local_addr() {
            return addr.ip();
        }
    }
    IpAddr::from([127,0,0,1])
}

fn parse_target_port() -> u16 {
    // Priority: --target-port <n> | -t <n> | positional number | env TARGET_PORT | default 80
    let args: Vec<String> = std::env::args().collect();
    let mut next_is_port = false;
    for a in args.iter().skip(1) {
        if next_is_port {
            if let Ok(p) = a.parse() { return p; }
            next_is_port = false;
        } else if a == "--target-port" || a == "-t" {
            next_is_port = true;
        } else if let Ok(p) = a.parse::<u16>() {
            return p;
        }
    }
    if let Ok(env_p) = std::env::var("TARGET_PORT") {
        if let Ok(p) = env_p.parse() { return p; }
    }
    80
}

fn main() {
    let target_port = parse_target_port();

    // Allow override for host IP (recommended when running in Docker)
    let ip_string = std::env::var("QR_HOST_IP")
        .unwrap_or_else(|_| discover_ip().to_string());

    let url = format!("http://{}:{}", ip_string, target_port);

    println!("(info) QR will encode: {url}");
    println!("(info) Serving the QR page on internal port 80 (map it with -p HOST:80)");

    let code = QrCode::new(url.as_bytes()).expect("qr gen failed");
    let svg_img = code
        .render()
        .min_dimensions(256, 256)
        .dark_color(svg::Color("#000"))
        .light_color(svg::Color("#fff"))
        .build();

    let html = format!(
        "<!doctype html><html><body style='display:flex;align-items:center;justify-content:center;height:100vh;flex-direction:column;font-family:sans-serif'>
           {svg_img}
           <p style='margin-top:1rem'>{url}</p>
         </body></html>"
    );

    let server = Server::http(("0.0.0.0", 80)).expect("bind failed");
    let header = Header::from_bytes(b"Content-Type", b"text/html").unwrap();
    println!("(ready) Visit http://localhost:<mapped_host_port> to view the QR (Ctrl+C to stop)");

    for req in server.incoming_requests() {
        let _ = req.respond(Response::from_string(html.clone()).with_header(header.clone()));
    }
}
