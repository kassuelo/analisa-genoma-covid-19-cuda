#include <stdio.h>
#include <cuda.h>

#define TAM 30800

//-----aloca memória global - na RAM e na GPU
__managed__ char vetor1[TAM];
__managed__ char vetor2[TAM];
__managed__ int qtd_iguais[10][10];

//------Kernel que sera executado na GPU
__global__ void compara_genoma(int *qtde)
{
	//a cada comparação de 2 arquivos serão iniciadas 30800 threads
	//cada thread ira comparar um caracter de cada arquivo
	// 30800 caracteres x 45 comparações = 1386000 threads iniciadas até o final das 45 comparações entre os 10 arquivos
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if ((vetor1[idx] != NULL) || (vetor2[idx] != NULL))
	{
		if (vetor1[idx] == vetor2[idx])
		{
			atomicAdd(qtde, 1);
		}
	}
	vetor1[idx] = NULL;
	vetor2[idx] = NULL;
}

void mostra_iguais()
{
    int maior_qtd_iguais=0;
    int arq1;
    int arq2;
    printf("\n MATRIZ IGUAIS\n");
    printf("\n arq0 | arq1 | arq2 | arq3 | arq4 | arq5 | arq6 | arq7 | arq8 | arq9 |\n\n");
    for (int i = 0; i < 10; i++)
    {
        for (int j = 0; j < 10; j++)
        {
            if(maior_qtd_iguais<qtd_iguais[i][j]){
                maior_qtd_iguais= qtd_iguais[i][j];
                arq1=i;
                arq2=j;
            }
            printf(" %5d|", qtd_iguais[i][j]);
        }
        printf("\n");
    }
    printf("\nMaior quantidade de iguais = %d, entre os genomas %d e %d\n\n",maior_qtd_iguais,arq1,arq2);
}

int main(int argc, char *argv[0])
{
	//-----cria uma var do tipo ponteiro
	int *num;
	//-----aloca memória na RAM e na GPU
	cudaMallocManaged(&num, 4);

	//-----inicializa endereço do ponteiro com 0
	*num = 0;
	srand(time(NULL));

	for (int j = 0; j < 9; j++)
	{
		for (int k = j + 1; k < 10; k++)
		{

			// Initializa vetor na CPU
			// envia dinamicamente o nome do arquivo de deve ser aberto
			char g1[14] = "genomas/";
			g1[8] = j + '0';
			strcat(g1, ".txt");
			char g2[14] = "genomas/";
			g2[8] = k + '0';
			strcat(g2, ".txt");

			char c; //guarda o caracter lido
			//abre o primeiro
			FILE *file1;
			file1 = fopen(g1, "r");
			int i = 0;
			while ((c = getc(file1)) != EOF)
			{
				vetor1[i] = c;
				i++;
			}
			fclose(file1);

			//abre o segundo arquivo
			FILE *file2;
			file2 = fopen(g2, "r");
			i = 0;
			while ((c = getc(file2)) != EOF)
			{
				vetor2[i] = c;
				i++;
			}
			fclose(file2);

			//-----programa principal exibe o vetor inicial
			printf("*COMPARANDO O ARQUIVO %d e o ARQUIVO %d", j, k);

			//-----executa a função compara_genoma na GPU com 30800 threads
			compara_genoma<<<700, 44>>>(num);

			//-----cria uma barreira - espera todas as threads finalizarem
			cudaDeviceSynchronize();

			qtd_iguais[j][k] = *num;
			*num = 0;
			printf("\n\n");
		}
	}
	mostra_iguais();
}
