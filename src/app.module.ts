import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseOrchestratorModule } from './config/database.orchestrator';
import { AiController } from './modules/ai/ai.controller';
import { HfInferenceService } from './modules/ai/hf-inference.service';
import { ArTryonModule } from './modules/ar-tryon/ar-tryon.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseOrchestratorModule,
    ArTryonModule,
  ],
  controllers: [AiController],
  providers: [HfInferenceService],
})
export class AppModule {}
