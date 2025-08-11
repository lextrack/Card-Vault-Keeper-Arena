using System;
using System.Diagnostics;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;

class Convertidor
{
    static void Main()
    {
        Console.WriteLine("=== Video Converter ===\n");

        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string ffmpegPath = Path.Combine(baseDir, "ffmpeg.exe");
        string ffprobePath = Path.Combine(baseDir, "ffprobe.exe");
        string inputDir = Path.Combine(baseDir, "input");
        string outputDir = Path.Combine(baseDir, "output");

        if (!File.Exists(ffmpegPath) || !File.Exists(ffprobePath))
            ExitWithMessage("Error: ffmpeg.exe and/or ffprobe.exe not found in the program folder.");

        Directory.CreateDirectory(inputDir);
        Directory.CreateDirectory(outputDir);

        string[] extensions = { "*.mp4", "*.mov", "*.avi", "*.mkv", "*.ogv", "*.webm" };
        var filesList = new List<string>();
        foreach (var ext in extensions)
            filesList.AddRange(Directory.GetFiles(inputDir, ext));

        if (filesList.Count == 0)
            ExitWithMessage("Error: No video files found in the 'input' folder.");

        Console.WriteLine("Available output formats:");
        Console.WriteLine("1) OGV (Theora/Vorbis)");
        Console.WriteLine("2) MP4 (H.264/AAC)");
        Console.WriteLine("3) WebM (VP9/Opus)");
        Console.Write("Select a format (1-3): ");
        string formatChoice = Console.ReadLine() ?? "1";

        Console.WriteLine("Resolutions 16:9 below 1280x720:");
        Console.WriteLine("1) 960x540\n2) 854x480\n3) 800x450\n4) 640x360\n5) Keep original");
        Console.Write("Select an option (1-5): ");
        string resChoice = Console.ReadLine() ?? "5";

        string scaleFilter = resChoice switch
        {
            "1" => "scale=960:540",
            "2" => "scale=854:480",
            "3" => "scale=800:450",
            "4" => "scale=640:360",
            _ => ""
        };

        Console.Write("Desired FPS (e.g., 30, 60, or leave empty to keep): ");
        string fpsInput = Console.ReadLine();
        string fpsFilter = !string.IsNullOrWhiteSpace(fpsInput) ? $"fps={fpsInput}" : "";

        string filterChain = "";
        if (!string.IsNullOrEmpty(scaleFilter) && !string.IsNullOrEmpty(fpsFilter))
            filterChain = $"{scaleFilter},{fpsFilter}";
        else if (!string.IsNullOrEmpty(scaleFilter))
            filterChain = scaleFilter;
        else if (!string.IsNullOrEmpty(fpsFilter))
            filterChain = fpsFilter;

        Console.Write("Keep audio? (y/n): ");
        bool keepAudio = (Console.ReadLine() ?? "n").Trim().ToLower() == "y";

        string extensionOut;
        string codecVideo;
        string codecAudio;

        switch (formatChoice)
        {
            case "2":
                extensionOut = ".mp4";
                codecVideo = "-vcodec libx264 -crf 23 -preset medium";
                codecAudio = keepAudio ? "-acodec aac -b:a 128k" : "-an";
                break;
            case "3":
                extensionOut = ".webm";
                codecVideo = "-vcodec libvpx-vp9 -b:v 1M";
                codecAudio = keepAudio ? "-acodec libopus -b:a 96k" : "-an";
                break;
            default:
                extensionOut = ".ogv";
                codecVideo = "-vcodec libtheora -q:v 8";
                codecAudio = keepAudio ? "-acodec libvorbis -q:a 6" : "-an";
                break;
        }

        foreach (var file in filesList)
        {
            string fileName = Path.GetFileNameWithoutExtension(file);
            string outputFileBase = Path.Combine(outputDir, $"{fileName}_converted{extensionOut}");
            string outputFile = outputFileBase;
            int counter = 1;
            while (File.Exists(outputFile))
            {
                outputFile = Path.Combine(outputDir, $"{fileName}_converted_{counter}{extensionOut}");
                counter++;
            }

            double totalSeconds = GetVideoDuration(ffprobePath, file);
            if (totalSeconds <= 0)
            {
                Console.WriteLine($"Skipping {fileName}, could not read duration.");
                continue;
            }

            string filterArg = !string.IsNullOrEmpty(filterChain) ? $"-vf \"{filterChain}\"" : "";
            string arguments = $"-i \"{file}\" {filterArg} {codecVideo} {codecAudio} \"{outputFile}\"";

            Console.WriteLine($"\nConverting: {Path.GetFileName(file)}");
            RunFFmpegWithProgress(ffmpegPath, arguments, totalSeconds);
            Console.WriteLine($"\nSaved to: {outputFile}");
        }

        ExitWithMessage("Process completed.\nConverted videos are in: " + outputDir);
    }

    static double GetVideoDuration(string ffprobePath, string filePath)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = ffprobePath,
                Arguments = $"-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \"{filePath}\"",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            using var proc = new Process();
            proc.StartInfo = psi;
            proc.Start();
            string result = proc.StandardOutput.ReadToEnd().Trim();
            proc.WaitForExit();
            return double.TryParse(result, out double seconds) ? seconds : 0;
        }
        catch
        {
            return 0;
        }
    }

    static void RunFFmpegWithProgress(string ffmpegPath, string arguments, double totalSeconds)
    {
        var psi = new ProcessStartInfo
        {
            FileName = ffmpegPath,
            Arguments = arguments,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var proc = new Process();
        proc.StartInfo = psi;
        proc.Start();

        var timeRegex = new Regex(@"time=(\d+):(\d+):(\d+\.?\d*)");
        while (!proc.StandardError.EndOfStream)
        {
            string line = proc.StandardError.ReadLine();
            if (line == null) continue;

            var match = timeRegex.Match(line);
            if (match.Success)
            {
                double hours = double.Parse(match.Groups[1].Value);
                double minutes = double.Parse(match.Groups[2].Value);
                double seconds = double.Parse(match.Groups[3].Value);
                double currentSeconds = hours * 3600 + minutes * 60 + seconds;
                int percent = (int)((currentSeconds / totalSeconds) * 100);
                DrawProgressBar(percent, 50);
            }
        }
        proc.WaitForExit();
    }

    static void DrawProgressBar(int percent, int width)
    {
        int filled = (int)((percent / 100.0) * width);
        Console.CursorLeft = 0;
        Console.Write("[");
        Console.Write(new string('█', filled));
        Console.Write(new string('-', width - filled));
        Console.Write($"] {percent}%");
    }

    static void ExitWithMessage(string message)
    {
        Console.WriteLine("\n" + message);
        Console.WriteLine("\nPress any key to exit...");
        Console.ReadKey();
        Environment.Exit(0);
    }
}
