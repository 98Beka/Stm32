#define    DWT_CYCCNT    *(volatile unsigned long *)0xE0001004
#define    DWT_CONTROL   *(volatile unsigned long *)0xE0001000
#define    SCB_DEMCR     *(volatile unsigned long *)0xE000EDFC
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
void delay_us(uint32_t us);
void delay_ms(uint32_t ms);
void UART_Init(void);

/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

 void delay_us(uint32_t us)
{
	int32_t us_count_tick =  us * (SystemCoreClock/1000000);
	//разрешаем использовать счётчик
	SCB_DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
        //обнуляем значение счётного регистра
	DWT_CYCCNT  = 0;
        //запускаем счётчик
	DWT_CONTROL |= DWT_CTRL_CYCCNTENA_Msk;
	while(DWT_CYCCNT < us_count_tick);
        //останавливаем счётчик
	DWT_CONTROL &= ~DWT_CTRL_CYCCNTENA_Msk;

}
void delay_ms(uint32_t ms)
{
	int32_t ms_count_tick =  ms * (SystemCoreClock/1000);
	//разрешаем использовать счётчик
	SCB_DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
         //обнуляем значение счётного регистра
	DWT_CYCCNT  = 0;
        //запускаем счётчик
	DWT_CONTROL|= DWT_CTRL_CYCCNTENA_Msk;
	while(DWT_CYCCNT < ms_count_tick);
        //останавливаем счётчик
	DWT_CONTROL &= ~DWT_CTRL_CYCCNTENA_Msk;

}
typedef struct {
	uint8_t HI; // целая часть влажности
	uint8_t HD; // дробная часть влажности
	uint8_t TI; // целая часть температуры
	uint8_t TD; // дробная часть температуры
	uint8_t crc; // контрольная сумма
} temp_s;
temp_s data;

void dht22_Init(void){
	RCC->APB2ENR |= RCC_APB2ENR_AFIOEN |RCC_APB2ENR_IOPBEN ;
	 //настраиваем вывод на вход с подтяжкой
					GPIOB->CRH |= GPIO_CRH_CNF12_0;
					GPIOB->CRH &=~ GPIO_CRH_CNF12_1;
					GPIOB->CRH |= GPIO_CRH_MODE12 ;
}
int dht22_GetData(temp_s *data)
{uint8_t i = 0;
GPIOB->ODR &= ~GPIO_ODR_ODR12;//низкий уровень
GPIOB->ODR |= GPIO_ODR_ODR12;//высокий уровень

delay_ms(100);
//передадим условие СТАРТ
GPIOB->ODR &= ~GPIO_ODR_ODR12;//низкий уровень

delay_ms(18);

GPIOB->ODR |= GPIO_ODR_ODR12;//высокий уровень

delay_us(39);//20-40 мкс //дождемся ответа датчика

if(GPIOB->IDR & GPIO_IDR_IDR12) {return 0;}//если датчик нам не ответил притягиванием шины, то ошибка

delay_us(80);

if(!(GPIOB->IDR & GPIO_IDR_IDR12)) {return 0;}//если датчик не отпустил шину, то ошибка
delay_us(80);

for(i=0; i<8; i++){

  while(!(GPIOB->IDR & GPIO_IDR_IDR12)); //ждём отпускания шины

  delay_us(30);
  if(GPIOB->IDR & GPIO_IDR_IDR12) //читаем результат по прошествии 30 микросекунд
  data->crc |= (1<<(7-i));
  while(GPIOB->IDR & GPIO_IDR_IDR12); //ждём, пока датчик притянет шину (в случае единицы)

}
  for(i=0; i<8; i++){

  while(!(GPIOB->IDR & GPIO_IDR_IDR12)); //ждём отпускания шины

  delay_us(30);
  if(GPIOB->IDR & GPIO_IDR_IDR12) //читаем результат по прошествии 30 микросекунд
  data->TD |= (1<<(7-i));
  while(GPIOB->IDR & GPIO_IDR_IDR12); //ждём, пока датчик притянет шину (в случае единицы)

}


  //////////////////////////////////////
  for(i=0; i<8; i++){

     while(!(GPIOB->IDR & GPIO_IDR_IDR12)); //ждём отпускания шины

     delay_us(30);
     if(GPIOB->IDR & GPIO_IDR_IDR12) //читаем результат по прошествии 30 микросекунд
     data->HD |= (1<<(7-i));
     while(GPIOB->IDR & GPIO_IDR_IDR12); //ждём, пока датчик притянет шину (в случае единицы)

   }
  for(i=0; i<8; i++){

   while(!(GPIOB->IDR & GPIO_IDR_IDR12)); //ждём отпускания шины

   delay_us(30);
   if(GPIOB->IDR & GPIO_IDR_IDR12) //читаем результат по прошествии 30 микросекунд
   data->TI |= (1<<(7-i));
   while(GPIOB->IDR & GPIO_IDR_IDR12); //ждём, пока датчик притянет шину (в случае единицы)

 }
  ///////////////////////////////



  for(i=0; i<8; i++){

   while(!(GPIOB->IDR & GPIO_IDR_IDR12)); //ждём отпускания шины

   delay_us(30);
   if(GPIOB->IDR & GPIO_IDR_IDR12) //читаем результат по прошествии 30 микросекунд
   data->HI |= (1<<(7-i));
   while(GPIOB->IDR & GPIO_IDR_IDR12); //ждём, пока датчик притянет шину (в случае единицы)

 }

	return 1;

}
void UART_Init (void){

	RCC->APB2ENR |= RCC_APB2ENR_USART1EN;  //тактирование
	RCC->APB2ENR |= RCC_APB2ENR_IOPAEN;    //тактирование
    RCC->APB2ENR |= RCC_APB2ENR_AFIOEN;    //тактирование

	GPIOA->CRH |= GPIO_CRH_CNF9_1;         //альтернативная ф-я, двухтактный выход
	GPIOA->CRH |= GPIO_CRH_MODE9;          //50MHz

	GPIOA->CRH |= GPIO_CRH_CNF10_0;        //плавающий вход
	GPIOA->CRH &= ~GPIO_CRH_MODE10;        //вход

	USART1->BRR = 0xD0;                    //настройка скорости тактирования

	USART1->CR1 |= USART_CR1_TE;           //
	USART1->CR1 |= USART_CR1_RE;
	USART1->CR1 |= USART_CR1_UE;

	USART1->CR1 |= USART_CR1_RXNEIE;
	NVIC_EnableIRQ(USART1_IRQn);

}
void USART1_Send (char chr){

	while (!(USART1->SR & USART_SR_TC));
	USART1->DR = chr;

}
void USART1_Send_String (char* str){

	uint8_t i = 0;

	while(str[i])
	USART1_Send (str[i++]);

}
char str[133];
uint8_t i=0;
uint8_t T=0;
uint8_t A=0;
void USART1_IRQHandler (void){

	if (USART1->SR & USART_CR1_RXNEIE){
		USART1->SR &= ~USART_CR1_RXNEIE;


		str[i]=USART1->DR;

		i++;
		if(i==134){
			i=0;
		}


		for(int i=0;i<133;i++){
			if(str[i]=='*' && str[i+3]=='*'){     //ищем *__* //пунктуация команды//между звездачками крманды управления мк
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			//здесь рекомендуется писать команды управления мк

				if(str[i+1]=='0'&&str[i+2]=='0'){
					GPIOB->ODR ^= GPIO_ODR_ODR9;
					str[i]='0';str[i+3]='0';  //очистка
					}

				if(str[i+1]=='0'&&str[i+2]=='1'){
					GPIOB->ODR ^= GPIO_ODR_ODR9;
					if(T==1){T=0;}else{T=1;}



					str[i]='0';str[i+3]='0';  //очистка
					}

				if(str[i+1]=='0'&&str[i+2]=='2'){
					GPIOB->ODR ^= GPIO_ODR_ODR9;
					if(A==1){A=0;}else{A=1;}

					str[i]='0';str[i+3]='0';  //очистка
					}




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      }
   }
}


}


void InitADC (void){

		RCC->APB2ENR |= RCC_APB2ENR_IOPAEN;
		RCC->APB2ENR |= RCC_APB2ENR_AFIOEN;

		GPIOA->CRL &= ~GPIO_CRL_CNF0;
	  GPIOA->CRL &= ~GPIO_CRL_MODE0;

		RCC->APB2ENR |= RCC_APB2ENR_ADC1EN;
		RCC->APB2ENR |= RCC_CFGR_ADCPRE_DIV2;

		ADC1->CR2 |= ADC_CR2_CAL; 														// start calibration
		while (!(ADC1->CR2 & ADC_CR2_CAL));                   // waiting end calibration

		ADC1->CR2 |= ADC_CR2_ADON;     												// enable ADC
		ADC1->CR2 &= ~ADC_CR2_CONT;														// 0 - single conversion, 1 - continuous conversion
		ADC1->CR2 |= ADC_CR2_EXTSEL;      										// event start conversion SWSTART
		ADC1->CR2 |= ADC_CR2_EXTTRIG;                         // enable start conversion external signal
		ADC1->SMPR1 |= ADC_SMPR1_SMP16; 											// sempling 239.5 cycle
		ADC1->SQR3 &= ~ADC_SQR3_SQ1;    											// selection channel

}

uint16_t StartConvADC (void){

		ADC1->CR2 |= ADC_CR2_SWSTART;

		while (!(ADC1->SR & ADC_SR_EOC));
		return (ADC1->DR);
}
void ESP_Init(void){
	RCC->APB2ENR |= RCC_APB2ENR_IOPBEN;
	GPIOB->CRH &= ~GPIO_CRH_CNF9;
	GPIOB->CRH	|= GPIO_CRH_MODE9;
	//GPIOB->ODR ^= GPIO_ODR_ODR9;
	  USART1_Send_String("AT+CIPMODE=0\r\n");
    delay_ms(150);
    USART1_Send_String("AT+CIPMUX=1\r\n");
	delay_ms(150);
	  USART1_Send_String("AT+CIPSERVER=1,80\r\n");
	delay_ms(150);


}

void InitTIM4(void){
	RCC->APB1ENR |= RCC_APB1ENR_TIM4EN;//разрешаем тактирование таймера

	TIM4->PSC = SystemCoreClock / 1000-1;//предделитель
	TIM4->ARR = 2500;//емкость счетчика

	TIM4->DIER |=TIM_DIER_UIE;
	TIM4->CR1 |=TIM_CR1_CEN;  //запуск таймера

	NVIC_EnableIRQ(TIM4_IRQn);//вызов прерывания

}

void TIM4_IRQHandler(void) {
	TIM4->SR &=~ TIM_SR_UIF;
if(T==1&&A==0){
	send_T();
}
if(A==1&&T==0){
	send_A();
}
if(A==1&&T==1){

char p[5];
GPIOB->ODR ^= GPIO_ODR_ODR9;
	  if(dht22_GetData(&data)==1){


		  switch(data.HD){
		  case 1:


		  if(data.TI>9){
		  USART1_Send_String("AT+CIPSEND=0,9\r\n");
		  }else{USART1_Send_String("AT+CIPSEND=0,8\r\n");}


		  itoa(data.TI, p, 10);
		  delay_ms(300);
		  USART1_Send_String("t: ");
		  USART1_Send_String(p);
		  USART1_Send_String("    ");
		  delay_ms(100);data.TI=0;data.HD=0;
		  break;
		  case 0:
			  if(data.TI>9){
			USART1_Send_String("AT+CIPSEND=0,9\r\n");
			}else{USART1_Send_String("AT+CIPSEND=0,8\r\n");}

		  itoa(250-data.TI, p, 10);
		  delay_ms(300);
		  USART1_Send_String("t: ");
		  USART1_Send_String(p);
		  USART1_Send_String("    ");
		  delay_ms(100);data.TI=0;data.HD=0;
		  break;
		  }
		  delay_ms(100);
		  GPIOB->ODR ^= GPIO_ODR_ODR9;
		  	 ADC1->CR2 |= ADC_CR2_SWSTART;
		  		  while (!(ADC1->SR & ADC_SR_EOC));

		  		  itoa(ADC1->DR/10, p, 10);

		  		  if((ADC1->DR/10)>99 && (ADC1->DR/10<1000)){
		  			  USART1_Send_String("AT+CIPSEND=0,10\r\n");
		  		  }
		  		  if((ADC1->DR/10)>9 && (ADC1->DR/10<100)){
		  		 			  USART1_Send_String("AT+CIPSEND=0,9\r\n");
		  		 		  }
		  		  if((ADC1->DR/1)>99 && (ADC1->DR/10<10)){
		  		 			  USART1_Send_String("AT+CIPSEND=0,8\r\n");

		  		 		  }
		  				  delay_ms(300);
		  				  USART1_Send_String("g: ");
		  				  USART1_Send_String(p);
		  				  USART1_Send_String("\"\r\n\"");
		  				  delay_ms(500);


}
}

}

void send_T(void){
	char p[5];
	GPIOB->ODR ^= GPIO_ODR_ODR9;
	  if(dht22_GetData(&data)==1){


		  switch(data.HD){
		  case 1:


		  if(data.TI>9){
		  USART1_Send_String("AT+CIPSEND=0,9\r\n");
		  }else{USART1_Send_String("AT+CIPSEND=0,8\r\n");}


		  itoa(data.TI, p, 10);
		  delay_ms(300);
		  USART1_Send_String("t: ");		 
		  USART1_Send_String(p);
		  USART1_Send_String("\"\r\n\"");
		  delay_ms(100);data.TI=0;data.HD=0;
		  break;
		  case 0:
			  if(data.TI>9){
			USART1_Send_String("AT+CIPSEND=0,9\r\n");
			}else{USART1_Send_String("AT+CIPSEND=0,8\r\n");}

		  itoa(250-data.TI, p, 10);
		  delay_ms(300);
		  USART1_Send_String("t: ");
		  USART1_Send_String(p);
		  USART1_Send_String("\"\r\n\"");
		  delay_ms(100);data.TI=0;data.HD=0;
		  break;
		  }

    delay_ms(1000);
	  }
}
void send_A(void){
	char p[5];
	GPIOB->ODR ^= GPIO_ODR_ODR9;
	 ADC1->CR2 |= ADC_CR2_SWSTART;
		  while (!(ADC1->SR & ADC_SR_EOC));

		  itoa(ADC1->DR/10, p, 10);

		  if((ADC1->DR/10)>99 && (ADC1->DR/10<1000)){
			  USART1_Send_String("AT+CIPSEND=0,10\r\n");
		  }
		  if((ADC1->DR/10)>9 && (ADC1->DR/10<100)){
		 			  USART1_Send_String("AT+CIPSEND=0,9\r\n");
		 		  }
		  if((ADC1->DR/1)>99 && (ADC1->DR/10<10)){
		 			  USART1_Send_String("AT+CIPSEND=0,8\r\n");

		 		  }
				  delay_ms(300);
				  USART1_Send_String("g: ");
				  USART1_Send_String(p);
				  USART1_Send_String("\"\r\n\"");
				  delay_ms(1000);


}


/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */
	__enable_irq (); //разрешаем прерывания глобально
		UART_Init();
		InitADC();
		dht22_Init();
		  InitTIM4();

