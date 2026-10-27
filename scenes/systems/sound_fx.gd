extends Node
class_name SoundFX

# 16-bit 44.1kHz temiz prosedürel ses sentezleyicisi (Yırtılma/clipping engellendi)
static var instance: SoundFX = null

func _enter_tree() -> void:
	instance = self

static func play_sound(type: String, volume_db: float = 0.0) -> void:
	if not instance:
		return
	var stream = instance._generate_sound(type)
	if stream:
		var asp = AudioStreamPlayer.new()
		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "Master"
		instance.add_child(asp)
		asp.finished.connect(asp.queue_free)
		asp.play()

func _generate_sound(type: String) -> AudioStreamWAV:
	var sample_rate = 44100
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var samples: PackedByteArray = PackedByteArray()
	
	match type:
		"pistol":
			# Tok tabanca patlaması (0.14 sn): alçak frekans vuruş + yumuşak gürültü kuyruğu
			var duration = 0.14
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 28.0)
				var punch = sin(t * TAU * 130.0 * exp(-t * 12.0))
				var noise = (randf() * 2.0 - 1.0)
				var val = (punch * 0.7 + noise * 0.3) * env * 0.75
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF
				
		"shotgun":
			# Derin ve tok çift kırma pompalı (0.35 sn): güçlü bas + zengin gürleme
			var duration = 0.35
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 11.0)
				var sub = sin(t * TAU * 85.0 * exp(-t * 6.0))
				var mid = sin(t * TAU * 160.0 * exp(-t * 14.0)) * 0.4
				var noise = (randf() * 2.0 - 1.0) * 0.4
				var val = (sub * 0.6 + mid + noise) * env * 0.8
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF
				
		"rocket_fire":
			# Roket fırlatma fısıltısı + gürültülü itiş (0.3 sn)
			var duration = 0.30
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 9.0)
				var whoosh = sin(t * TAU * (120.0 + t * 400.0)) * 0.5
				var thruster = (randf() * 2.0 - 1.0) * 0.6
				var val = (whoosh + thruster) * env * 0.8
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"explosion":
			# Ağır patlama ve derin bas yankısı (0.55 sn)
			var duration = 0.55
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 6.5)
				var sub_boom = sin(t * TAU * 65.0 * exp(-t * 5.0)) * 0.7
				var boom_noise = (randf() * 2.0 - 1.0) * 0.6
				var val = (sub_boom + boom_noise) * env * 0.9
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"enemy_hit":

			# Kağıt delinmesi + tok darbe sesi (0.08 sn)
			var duration = 0.08
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 40.0)
				var thud = sin(t * TAU * 110.0)
				var tear = (randf() * 2.0 - 1.0) * sin(t * TAU * 450.0) * 0.5
				var val = (thud * 0.6 + tear * 0.4) * env * 0.7
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF
				
		"finisher":
			# Karton/Kağıt yırtılması + tok bas vuruşu (0.42 sn)
			var duration = 0.42
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				# 1. Yırtılma hışırtısı (Kağıt liflerinin çatırdayarak kopması)
				var rip_env = exp(-t * 12.0)
				var tear_freq = 600.0 + sin(t * 80.0) * 300.0
				var rip_friction = (randf() * 2.0 - 1.0) * sin(t * TAU * tear_freq)
				
				# 2. Tok bas darbesi (İnfaz ağırlığı)
				var punch_env = exp(-t * 7.0)
				var bass_punch = sin(t * TAU * (85.0 - t * 45.0))
				
				var val = (rip_friction * 0.55 * rip_env) + (bass_punch * 0.65 * punch_env)
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

				
		"pickup":
			# Temiz, yumuşak retro chiptune tonu (0.11 sn)
			var duration = 0.11
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 520.0 + (t / duration) * 440.0
				var wave = sin(t * TAU * freq)
				var env = (1.0 - (t / duration)) * min(1.0, t * 100.0)
				var val = wave * env * 0.55
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF
				
		"empty":
			# Yumuşak tetik tıkı (0.04 sn)
			var duration = 0.04
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 70.0)
				var click = sin(t * TAU * 850.0)
				var val = click * env * 0.5
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"footstep":
			# Hafif karton/zemin adım pıtırtısı (0.06 sn)
			var duration = 0.06
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 60.0)
				var tap = sin(t * TAU * 140.0 * exp(-t * 20.0)) * 0.6
				var scuff = (randf() * 2.0 - 1.0) * 0.4
				var val = (tap + scuff) * env * 0.4
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"jump":
			# Zıplama yükselme efekti (0.12 sn)
			var duration = 0.12
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = (1.0 - (t / duration))
				var freq = 120.0 + (t / duration) * 220.0
				var val = sin(t * TAU * freq) * env * 0.45
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"land":
			# Yere sert iniş darbesi (0.14 sn)
			var duration = 0.14
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 22.0)
				var thud = sin(t * TAU * 80.0 * exp(-t * 10.0)) * 0.8
				var rustle = (randf() * 2.0 - 1.0) * 0.3
				var val = (thud + rustle) * env * 0.65
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"dash":
			# Hızlı hava yarılması ve rüzgar hışırtısı (0.22 sn)
			var duration = 0.22
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = sin((t / duration) * PI) * exp(-t * 4.0)
				var sweep = sin(t * TAU * (280.0 - t * 400.0)) * 0.4
				var wind = (randf() * 2.0 - 1.0) * 0.6
				var val = (sweep + wind) * env * 0.7
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"jumppad":
			# Güçlü yay fırlaması ve hava hışırtısı (0.28 sn)
			var duration = 0.28
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 8.0)
				var sweep = sin(t * TAU * (140.0 + (t / duration) * 450.0)) * 0.75
				var sub = sin(t * TAU * 90.0) * 0.35
				var val = (sweep + sub) * env * 0.85
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"punch_swing":
			# Hızlı yumruk savurma ve hava kırbacı (0.12 sn)
			var duration = 0.12
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = sin((t / duration) * PI)
				var sweep = sin(t * TAU * (450.0 - (t / duration) * 280.0)) * 0.5
				var wind = (randf() * 2.0 - 1.0) * 0.4
				var val = (sweep + wind) * env * 0.6
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

		"punch_hit":
			# Tok kemik ve et darbesi (0.16 sn)
			var duration = 0.16
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples * 2)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var env = exp(-t * 24.0)
				var thud = sin(t * TAU * 110.0 * exp(-t * 14.0)) * 0.8
				var snap = (randf() * 2.0 - 1.0) * 0.4 * exp(-t * 40.0)
				var val = (thud + snap) * env * 0.95
				var int16 = int(clamp(val * 32767.0, -32767.0, 32767.0))
				samples[i * 2] = int16 & 0xFF
				samples[i * 2 + 1] = (int16 >> 8) & 0xFF

	wav.data = samples
	return wav
