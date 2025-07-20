use local_ip_address::local_ip;
use qrcode::QrCode;
use qrcode::render::svg;
use tiny_http::{Server, Response, Header};

fn main() {
    // Read optional first CLI arg as port, default 80
    let port: u16 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(80);

    let ip = local_ip().expect("could not get local ip");
    let url = format!("http://{}:{}", ip, port);

    // Build QR and render straight to SVG (string)
    let code = QrCode::new(url.as_bytes()).expect("qr gen failed");
    let svg = code
        .render()
        .min_dimensions(256, 256)
        .dark_color(svg::Color("#000"))
        .light_color(svg::Color("#fff"))
        .build();

    // Embed SVG inline (no base64)
    let html = format!(
        "<!doctype html><html><body style='display:flex;align-items:center;justify-content:center;height:100vh;flex-direction:column;font-family:sans-serif'>
           {svg}
           <p style='margin-top:1rem'>{url}</p>
         </body></html>"
    );

    let server = Server::http(("0.0.0.0", port)).expect("server start failed");
    println!("Serving QR for {url} on http://localhost:{port}");

    let ct = Header::from_bytes(b"Content-Type", b"text/html").unwrap();

    for req in server.incoming_requests() {
        let _ = req.respond(
            Response::from_string(html.clone())
                .with_header(ct.clone())
        );
    }
}
