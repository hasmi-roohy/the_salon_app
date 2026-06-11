import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors();

  // ✅ Global validation pipe
  // - Validates all DTOs against class-validator decorators
  // - whitelist: true → removes unknown properties
  // - transform: true → automatically converts types (string → number, etc)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  await app.listen(3000);
  console.log('===================================================');
  console.log('🚀 SALOON-OS BACKEND SUCCESSFULLY BOOTED ON PORT 3000');
  console.log('===================================================');
  console.log('📝 Validation: ENABLED (class-validator)');
  console.log('🔐 Auth: DISABLED (dev mode) - set AUTH_DISABLED=false when ready');
  console.log('===================================================');
}

bootstrap();