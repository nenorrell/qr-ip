use clap::Parser;
use local_ip_address::local_ip;
use qrcode::QrCode;
use qrcode::render::unicode; // only if you want a terminal fallback
use image::Rgb;
use show_image::{create_window, ImageInfo, ImageView, WindowOptions};

/// Simple tool to show a QR code of your LAN IP + port
#[derive(Parser)]
#[command(name = "qr-ip")]
struct Cli {
    /// Port to embed in the URL (default: 80)
    #[arg(short, long, default_value = "80")]
    port: u16,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 1) parse port
    let cli = Cli::parse();

    // 2) get local IP (first non-loopback IPv4)
    let ip = local_ip()?;
    let url = format!("http://{}:{}", ip, cli.port);

    // 3) generate QR code (RGB image, 256×256px)
    let code = QrCode::new(url.as_bytes())?;
    let image = code
        .render::<Rgb<u8>>()
        .min_dimensions(256, 256)
        .dark_color(Rgb([0, 0, 0]))
        .light_color(Rgb([255, 255, 255]))
        .build();
    let (w, h) = (image.width(), image.height());
    let raw = image.into_raw(); // Vec<u8>, 3×w×h bytes

    // 4) open a window and show it
    //    (show-image uses glutin/OpenGL under the hood)
    show_image::make_window_builder()
        .with_title("QR Code for your LAN URL")
        .with_inner_size((w as u32, h as u32))
        .build()?;
    let window = create_window("qr", WindowOptions::default())?;
    window.set_image(
        "qr",
        ImageView::new(ImageInfo::rgb8(w, h), &raw),
    )?;

    // 5) block until the window is closed
    window.wait_until_destroyed()?;
    Ok(())
}
