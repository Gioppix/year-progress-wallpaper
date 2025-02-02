use ab_glyph::{FontRef, PxScale};
use chrono::{Datelike, Local, NaiveDate};
use image::{Rgb, RgbImage};
use imageproc::drawing::{draw_text_mut, text_size};
use std::{fs, path::Path, sync::LazyLock};

pub fn set_from_path(path: &str) -> Result<(), std::io::Error> {
    let script = format!(
        r#"tell application "System Events" to tell every desktop to set picture to "{}""#,
        path,
    );

    let res = std::process::Command::new("osascript")
        .args(&["-e", &script])
        .output()?;

    Ok(())
}

const BASE_PATH: &str = "/var/tmp/yearprogress/wallpaper/";

static FONT: LazyLock<FontRef> = LazyLock::new(|| {
    FontRef::try_from_slice(include_bytes!("../assets/ZedPlexMono-Regular.ttf")).unwrap()
});

fn calculate_year_percentage() -> f64 {
    let now = Local::now();
    let current_year = now.year();

    // Get start and end of the year
    let year_start = NaiveDate::from_ymd_opt(current_year, 1, 1)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap();

    let year_end = NaiveDate::from_ymd_opt(current_year + 1, 1, 1)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap();

    // Calculate total duration and elapsed duration
    let total_duration = year_end.signed_duration_since(year_start);
    let elapsed_duration = now.naive_local().signed_duration_since(year_start);

    // Calculate percentage
    (elapsed_duration.num_seconds() as f64 / total_duration.num_seconds() as f64) * 100.0
}

fn set_picture() {
    let seconds = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();

    let scale = PxScale::from(60.0);

    let text = format!("{:.6}%", calculate_year_percentage());

    // Get text dimensions
    let (text_width, text_height) = text_size(scale, &*FONT, &text);

    fs::remove_dir_all(BASE_PATH).expect("remove path");
    fs::create_dir(BASE_PATH).expect("create path");

    let path = &format!("{}{}.tiff", BASE_PATH, seconds);

    let mut image = RgbImage::new(text_width, text_height * 2);

    // image = draw_filled_rect(
    //     &mut image,
    //     Rect::at(400, pos).of_size(600, 700),
    //     Rgb([0u8, 255u8, 255u8]),
    // );

    draw_text_mut(
        &mut image,
        Rgb([255u8, 255u8, 255u8]),
        0,
        0,
        scale,
        &*FONT,
        &text,
    );
    // let (w, h) = text_size(scale, &font, text);
    // println!("Text size: {}x{}", w, h);

    image.save(path).expect("save image");

    set_from_path(path).expect("no err");
}

fn main() {
    fs::create_dir_all(Path::new(BASE_PATH)).expect("create");

    loop {
        set_picture();
        std::thread::sleep(std::time::Duration::from_millis(1000));
    }
}
