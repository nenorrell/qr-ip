use qrcode::QrCode;
use qrcode::render::svg;
use tiny_http::{Server, Response, Header};
use std::net::{UdpSocket, IpAddr, ToSocketAddrs};

fn resolve_host_gateway() -> Option<IpAddr> {
    // Try to resolve host.docker.internal
    ("host.docker.internal", 80).to_socket_addrs().ok()
        .and_then(|mut iter| iter.find(|a| matches!(a.ip(), IpAddr::V4(_))).map(|a| a.ip()))
}

fn udp_self_ip() -> Option<IpAddr> {
    let sock = UdpSocket::bind("0.0.0.0:0").ok()?;
    let _ = sock.connect("1.1.1.1:80");
    sock.local_addr().ok().map(|a| a.ip())
}

fn choose_ip() -> (String, bool) {
    if let Ok(ip) = std::env::var("HOST_IP") {
        return (ip, true); // trusted
    }
    if let Some(gw) = resolve_host_gateway() {
        return (gw.to_string(), false); // gateway, maybe not LAN
    }
    if let Some(self_ip) = udp_self_ip() {
        return (self_ip.to_string(), false);
    }
    ("127.0.0.1".into(), false)
}

fn parse_target_port() -> u16 {
    std::env::args().nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(80)
}

fn main() {
    let target_port = parse_target_port();
    let (ip, trusted) = choose_ip();
    if !trusted {
        eprintln!("(warn) Using '{ip}' (likely container/gateway IP). For LAN devices set HOST_IP to your host Wi-Fi IP (e.g. 192.168.x.x).");
    }
    let url = format!("http://{ip}:{target_port}");
    println!("(info) QR encodes: {url}");
    println!("(info) Serving page on 0.0.0.0:80 (map with -p <host>:80)");

    let code = QrCode::new(url.as_bytes()).expect("QR gen failed");
    let svg_img = code.render()
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
    println!("(ready) Open http://localhost:80>");

    for req in server.incoming_requests() {
        let _ = req.respond(Response::from_string(html.clone()).with_header(header.clone()));
    }
}
