
all: compile

compile:
	nvcc -o executa_analise_CUDA AnalisaGenoma_CUDA.cu -lm

clean:
	rm -rf ?