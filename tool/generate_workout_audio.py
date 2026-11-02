"""Generate original CC0 workout cue sounds using additive synthesis."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def write(name, duration, tones):
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        value = 0
        for frequency, start, decay in tones:
            elapsed = t - start
            if elapsed >= 0:
                envelope = min(1, elapsed / .008) * math.exp(-elapsed / decay)
                value += math.sin(2 * math.pi * frequency * elapsed) * envelope
        samples.append(struct.pack('<h', round(max(-1, min(1, value * .22)) * 32767)))
    target = ROOT / 'assets' / 'audio' / (name + '.wav')
    target.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(target), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(samples))
    return target


if __name__ == '__main__':
    write('countdown', .18, [(880, 0, .045)])
    write('metronome', .12, [(1200, 0, .018), (600, 0, .014)])
    write('bell', .65, [(660, 0, .18), (1320, 0, .12), (1980, 0, .09)])
    completion = write('complete', .9, [(660, 0, .18), (880, .15, .18), (1100, .3, .22)])
    native = ROOT / 'android' / 'app' / 'src' / 'main' / 'res' / 'raw' / 'complete.wav'
    native.parent.mkdir(parents=True, exist_ok=True)
    native.write_bytes(completion.read_bytes())
